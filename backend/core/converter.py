import re

# [FIX] ลบ _DECIMAL_FAMILY ออก — ไม่ใช้แล้ว เพราะเช็ค logical_type แทน
# เดิมเช็ค source SQL type (base) ∈ DECIMAL_FAMILY ซึ่ง false positive ทุก binary type
# เช่น binary, varbinary, bytea, blob, image ล้วน raw='bytes' แต่ logical='bytes' (ถูกต้อง)
# byte anomaly จริงๆ คือ: raw='bytes' แต่ logical ไม่ใช่ 'decimal'
# เพราะ Avro spec กำหนดให้ decimal type store เป็น bytes → logical='decimal' raw='bytes' = ปกติ
# แต่ถ้า logical='bytes' (ไม่ใช่ decimal) แล้ว raw='bytes' ก็ยังปกติ (binary type)
# → anomaly จริงๆ มีแค่กรณีที่ raw='bytes' แต่ logical เป็นอะไรแปลกๆ ที่ไม่ควรเป็น bytes

# raw_type ที่ถือว่าเป็น "byte output" ใน Avro
_BYTE_RAW_TYPES = {"bytes", "byte", "byte[]", "binary"}

# logical_type ที่ OK เมื่อ raw='bytes' (Avro decimal stored as bytes, หรือ binary type ปกติ)
_BYTES_OK_LOGICAL = {"decimal", "bytes"}


class DataTypeConverter:
    def __init__(self, mapping: dict):
        """
        mapping: dict ที่โหลดจาก DB (อาจเป็น default mapping หรือ per-db-pair)
        เก็บเป็น default; convert() รับ override_mapping เพื่อใช้แทนได้
        """
        self.mapping = mapping

    def normalize(self, sql_type: str) -> str:
        t = sql_type.lower().strip()
        return re.split(r"[\(\s]", t)[0]

    def apply_precision(self, sql_type: str, base: str, final_type: str) -> str:
        """
        ต่อ (n) หรือ (p,s) กลับเข้า final_type จาก sql_type ต้นทาง
        base  = normalized base type เช่น 'varchar', 'money'
        """
        if base in ("money", "smallmoney", "timestamp", "rowversion"):
            return final_type

        if "(" in final_type:
            return final_type

        match = re.search(r"\(([^)]+)\)", sql_type)

        needs_precision = {
            "decimal", "numeric",
            "varchar", "char",
            "nvarchar", "nchar",
            "binary", "varbinary",
        }

        if base in needs_precision and match:
            return f"{final_type}({match.group(1)})"

        if base in ("decimal", "numeric") and not match:
            return f"{final_type}(18,0)"

        return final_type

    def convert(self, sql_type: str, override_mapping: dict | None = None) -> dict:
        """
        แปลง sql_type → result dict

        override_mapping: ถ้าส่งมา จะใช้แทน self.mapping
                          ใช้สำหรับ per-db-pair mapping
        """
        mapping = override_mapping if override_mapping is not None else self.mapping
        base = self.normalize(sql_type)
        data = mapping.get(base)

        if not data:
            return {
                "input": sql_type, "raw": None, "logical": None, "final": None,
                "status": "unknown", "reason": f"Type '{base}' not found in mapping"
            }

        final = self.apply_precision(sql_type, base, data["final"])

        # ── ตรวจ byte anomaly ────────────────────────────────────
        # [FIX] เช็ค logical_type แทน source base type
        # raw='bytes' + logical='decimal' → Avro decimal (ถูกต้อง ไม่ใช่ anomaly)
        # raw='bytes' + logical='bytes'   → binary type ปกติ (ถูกต้อง ไม่ใช่ anomaly)
        # raw='bytes' + logical=อื่นๆ     → น่าสงสัย ให้ flag
        raw_type_lower = (data["raw"] or "").lower().strip()
        logical_lower = (data["logical"] or "").lower().strip()
        is_byte_output = raw_type_lower in _BYTE_RAW_TYPES
        byte_anomaly = is_byte_output and logical_lower not in _BYTES_OK_LOGICAL

        return {
            "input": sql_type,
            "raw": data["raw"],
            "logical": data["logical"],
            "final": final,
            "status": "ok",
            "reason": None,
            "byte_anomaly": byte_anomaly,
            "byte_anomaly_detail": (
                f"คอลัมน์ถูกแปลงเป็น '{data['raw']}' "
                f"แต่ logical type เป็น '{data['logical']}' — "
                f"กรุณาตรวจสอบ mapping"
            ) if byte_anomaly else None,
        }
