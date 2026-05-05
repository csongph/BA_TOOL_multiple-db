import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from typing import List
import os

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Request, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, field_validator
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from backend.repository.mapping_repo import MappingRepository
from backend.core.converter import DataTypeConverter
from backend.parser.sql_parser import parse_sql, validate_fk
from backend.config.logger import logger
from backend.config.db import init_db_pool, close_db_pool
from backend.core.cache_store import result_cache
from backend.exporter.excel_exporter import export_confluent_xlsx, export_table_xlsx, export_all_csv, export_table_csv

# ── Constants ────────────────────────────────────────────
MAX_FILE_SIZE_MB = 10
MAX_FILE_SIZE = MAX_FILE_SIZE_MB * 1024 * 1024
MAX_FILES = 20
SESSION_TTL = timedelta(hours=1)

# Bug 3 Fix: ไม่ต้องใช้ global mapping_data และ converter ที่โหลดตอน startup อีกต่อไป
# แต่ยังคงเก็บ converter ไว้เป็น singleton instance สำหรับฟังก์ชันพื้นฐาน (ถ้าจำเป็น)
converter: DataTypeConverter = DataTypeConverter({})

limiter = Limiter(key_func=get_remote_address)

# ── Lifecycle ─────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 Starting up...")
    try:
        init_db_pool()
        # Bug 3 Fix: ย้ายการโหลด mapping ออกจาก startup
        logger.info("✅ Database pool initialized. Mapping will be loaded per request.")
    except Exception as e:
        logger.error(f"❌ Startup failed: {e}", exc_info=True)
        raise
    yield
    logger.info("🛑 Shutdown")
    close_db_pool()

app = FastAPI(lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS ─────────────────────────────────────────────────
# [FIX] เพิ่ม localhost:8000 และ 127.0.0.1:8000 เพื่อแก้ CORS blocked
# ถ้าต้องการ lock down ใน production ให้ set env ALLOWED_ORIGINS แทน
_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "http://localhost:5500,http://127.0.0.1:5500,http://localhost:8000,http://127.0.0.1:8000"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=_ORIGINS,
    allow_credentials=True,          # ← เพิ่มบรรทัดนี้
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["Content-Type"],
)

# ── Models ────────────────────────────────────────────────
class OverrideRequest(BaseModel):
    table: str
    column: str
    new_type: str

    @field_validator("table", "column", "new_type")
    @classmethod
    def no_empty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Field must not be empty")
        if len(v) > 256:
            raise ValueError("Field too long")
        return v

# ── Helpers ───────────────────────────────────────────────
def cleanup_expired_sessions() -> None:
    now = datetime.now()
    expired = [sid for sid, s in result_cache.items()
               if now - s["created_at"] > SESSION_TTL]
    for sid in expired:
        del result_cache[sid]
    if expired:
        logger.info(f"🧹 Cleaned {len(expired)} expired session(s)")

def get_cached_data(session_id: str) -> dict:
    cleanup_expired_sessions()
    data = result_cache.get(session_id)
    if not data:
        raise HTTPException(404, "Session expired or not found")
    return data

def _load_mapping(source_db: str | None, dest_db: str | None) -> dict:
    """
    โหลด mapping ตาม db pair
    - Bug 3 Fix: โหลดจาก DB เสมอตาม source_db ที่ระบุ เพื่อป้องกันข้อมูลปนกัน
    """
    repo = MappingRepository()
    
    # 1. ถ้ามีทั้งคู่ -> ดึง per-pair mapping
    if source_db and dest_db:
        try:
            pair_mapping = repo.get_by_db_pair(source_db, dest_db)
            if pair_mapping:
                logger.info(f"📦 Pair mapping loaded: {source_db} → {dest_db} ({len(pair_mapping)} types)")
                return pair_mapping
        except Exception as e:
            logger.warning(f"⚠️ Failed to load pair mapping ({source_db}→{dest_db}): {e}")

    # 2. ถ้ามีแค่ source_db หรือโหลด pair ไม่สำเร็จ -> ดึง mapping ของ source_db นั้นๆ
    if source_db:
        try:
            source_mapping = repo.get_all(source_db=source_db)
            logger.info(f"📦 Source mapping loaded for {source_db} ({len(source_mapping)} types)")
            return source_mapping
        except Exception as e:
            logger.error(f"❌ Failed to load source mapping for {source_db}: {e}")

    # 3. Fallback สุดท้าย (ไม่แนะนำ) -> ดึงทั้งหมดแบบระบุไม่ได้ (อาจปนกัน)
    logger.warning("⚠️ No source_db specified, loading all mappings (potential mix-up)")
    return repo.get_all()

# ── API ───────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "sessions": len(result_cache)}

@app.get("/db-pairs")
def get_db_pairs():
    """
    คืนรายการ source_db / dest_db ที่มี mapping ใน DB
    Frontend ใช้เพื่อ populate dropdown แบบ dynamic
    """
    try:
        repo = MappingRepository()
        pairs = repo.get_available_db_pairs()
        return {"pairs": pairs}
    except Exception as e:
        logger.error(f"❌ Failed to fetch db pairs: {e}")
        raise HTTPException(500, "Failed to fetch DB pairs")

@app.post("/convert")
@limiter.limit("30/minute")
async def convert(
    request: Request,
    files: List[UploadFile] = File(...),
    source_db: str | None = Form(default=None),
    dest_db: str | None = Form(default=None),
):
    if len(files) > MAX_FILES:
        raise HTTPException(400, f"Too many files (max {MAX_FILES})")

    # Bug 3 Fix: โหลด mapping สดๆ ใน request นี้เลย
    active_mapping = _load_mapping(source_db, dest_db)
    
    logger.info(
        f"📥 Convert {len(files)} file(s) "
        f"[{source_db or 'default'} → {dest_db or 'default'}]"
    )

    tables: dict = {}
    unknown: dict = {}
    table_source: dict = {}
    duplicate_tables: dict = {}
    byte_anomalies: dict = {}

    for file in files:
        filename = file.filename
        try:
            raw = await file.read()
            if len(raw) > MAX_FILE_SIZE:
                raise HTTPException(400, f"{filename}: exceeds {MAX_FILE_SIZE_MB} MB limit")
            sql_text = raw.decode("utf-8-sig")
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"❌ Error reading {filename}: {e}")
            raise HTTPException(400, f"Cannot read file: {filename}")

        parsed = parse_sql(sql_text)
        if not parsed:
            logger.warning(f"  ⚠️ No table found in: {filename}")
            continue

        parsed_by_table: dict = {}
        for row in parsed:
            parsed_by_table.setdefault(row["table"], []).append(row)

        for table, table_rows in parsed_by_table.items():
            is_duplicate = False
            if table in table_source:
                dup = duplicate_tables.setdefault(table, {
                    "first_file":      table_source[table],
                    "duplicate_files": [],
                })
                if filename not in dup["duplicate_files"]:
                    dup["duplicate_files"].append(filename)
                    logger.warning(
                        f"⚠️  Duplicate table '{table}' in '{filename}' "
                        f"(first defined in '{table_source[table]}')"
                    )
                is_duplicate = True
                table_key = f"{table}__{filename}"
            else:
                table_source[table] = filename
                table_key = table

            for row in table_rows:
                # ใช้ active_mapping ที่โหลดมาสดๆ ในการ convert
                res = converter.convert(row["type"], override_mapping=active_mapping)
                
                col_entry = {
                    "column_name":     row["column"],
                    "file":            filename,
                    "raw_type":        res.get("raw"),
                    "logical_type":    res.get("logical"),
                    "standard_type":   res.get("standard_type"),
                    "final_type":      res.get("final") if res.get("status") == "ok" else row["type"],
                    "source_sql_type": row["type"],
                    "nullable":        "NOT NULL" if row.get("nullable") == "NOT NULL" else "NULL",
                    "is_pk":           row.get("is_pk", False),
                    "fk":              row.get("fk"),
                    "is_duplicate":    is_duplicate,
                }
                tables.setdefault(table_key, []).append(col_entry)

                if res.get("status") != "ok":
                    unknown.setdefault(table_key, []).append({
                        "column": row["column"],
                        "type":   row["type"],
                        "file":   filename,
                    })
                
                # ตรวจสอบ byte anomalies (เช่น binary types)
                if res.get("raw") == "bytes" or "blob" in str(row["type"]).lower():
                    byte_anomalies.setdefault(table_key, []).append(row["column"])

    # Validate foreign keys
    fk_errors = validate_fk(tables)

    session_id = str(uuid.uuid4())
    result_cache[session_id] = {
        "tables":           tables,
        "unknown":          unknown,
        "fk_errors":        fk_errors,
        "byte_anomalies":   byte_anomalies,
        "duplicate_tables": duplicate_tables,
        "source_db":        source_db,
        "dest_db":          dest_db,
        "created_at":       datetime.now(),
    }

    logger.info(f"✅ Session {session_id} created — {len(tables)} table(s)")
    
    return {
        "session_id":       session_id,
        "file_count":       len(files),
        "source_db":        source_db,
        "dest_db":          dest_db,
        "tables":           tables,
        "unknown":          unknown,
        "fk_errors":        fk_errors,
        "byte_anomalies":   byte_anomalies,
        "duplicate_tables": duplicate_tables,
    }

@app.get("/result/{session_id}")
def get_result(session_id: str):
    return get_cached_data(session_id)

@app.post("/override/{session_id}")
def override(session_id: str, body: OverrideRequest):
    data = get_cached_data(session_id)
    table_cols = data["tables"].get(body.table)
    if table_cols is None:
        raise HTTPException(404, f"Table '{body.table}' not found")
    
    for col in table_cols:
        if col["column_name"] == body.column:
            col["final_type"] = body.new_type
            logger.info(f"✏️  Override {body.table}.{body.column} → {body.new_type}")
            return {"updated_column": col}
            
    raise HTTPException(404, f"Column '{body.column}' not found in table '{body.table}'")

@app.delete("/session/{session_id}")
def delete_session(session_id: str):
    try:
        uuid.UUID(session_id)
    except ValueError:
        raise HTTPException(400, "Invalid session ID format")
        
    if session_id in result_cache:
        del result_cache[session_id]
        logger.info(f"🗑  Session {session_id} deleted")
        return {"status": "deleted"}
    raise HTTPException(404, "Session not found")

# ── Export endpoints ──────────────────────────────────────
@app.get("/export/{session_id}/xlsx")
def export_all(session_id: str, tables: List[str] = Query(default=None)):
    data = get_cached_data(session_id)
    all_tables = data["tables"]
    selected = {k: v for k, v in all_tables.items() if tables is None or k in tables}
    byte_anomalies = {k: v for k, v in data.get("byte_anomalies", {}).items() if k in selected}
    
    buf = export_confluent_xlsx(
        selected,
        byte_anomalies=byte_anomalies,
        source_db=data.get("source_db"),
        dest_db=data.get("dest_db"),
    )
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=confluent_mapping.xlsx"},
    )

@app.get("/export/{session_id}/xlsx/{table_name}")
def export_one(session_id: str, table_name: str):
    data = get_cached_data(session_id)
    columns = data["tables"].get(table_name)
    if columns is None:
        raise HTTPException(404, f"Table '{table_name}' not found")
    
    anomalies = data.get("byte_anomalies", {}).get(table_name)
    buf = export_table_xlsx(
        columns,
        table_name,
        anomalies=anomalies,
        source_db=data.get("source_db"),
        dest_db=data.get("dest_db"),
    )
    filename = f"{table_name}.xlsx"
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )

@app.get("/export/{session_id}/csv")
def export_all_csv_endpoint(session_id: str, tables: List[str] = Query(default=None)):
    data = get_cached_data(session_id)
    all_tables = data["tables"]
    selected = {k: v for k, v in all_tables.items() if tables is None or k in tables}
    byte_anomalies = {k: v for k, v in data.get("byte_anomalies", {}).items() if k in selected}
    
    buf = export_all_csv(selected, byte_anomalies=byte_anomalies)
    return StreamingResponse(
        buf,
        media_type="text/csv; charset=utf-8-sig",
        headers={"Content-Disposition": "attachment; filename=confluent_mapping.csv"},
    )

@app.get("/export/{session_id}/csv/{table_name}")
def export_one_csv(session_id: str, table_name: str):
    data = get_cached_data(session_id)
    columns = data["tables"].get(table_name)
    if columns is None:
        raise HTTPException(404, f"Table '{table_name}' not found")
    
    anomalies = data.get("byte_anomalies", {}).get(table_name)
    buf = export_table_csv(columns, table_name, anomalies=anomalies)
    filename = f"{table_name}.csv"
    return StreamingResponse(
        buf,
        media_type="text/csv; charset=utf-8-sig",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )