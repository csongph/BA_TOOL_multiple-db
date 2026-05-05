from backend.config.db import get_connection, release_connection


class MappingRepository:
    # Query หลัก: JOIN 3 ทาง
    #   datatype_raw_mapping  (source type → Avro raw/logical)
    #   datatype_standard     (standard type กลาง)
    #   datatype_mapping      (dest DB final type)
    #
    # ผลลัพธ์มี 2 final_type:
    #   standard_type  = Confluent/Avro standard (เหมือนกันทุก dest)
    #   dest_type      = SQL type จริงของ dest DB (ต่างกันตาม dest)
    _SELECT = """
        SELECT
            drm.source_type     AS sql_type,
            drm.raw_type,
            drm.logical_type,
            ds.standard_type,
            dm.final_type       AS dest_type,
            drm.db_id           AS source_db_id,
            dm.db_id            AS dest_db_id,
            dm.has_length,
            dm.has_precision,
            dm.has_scale
        FROM datatype_raw_mapping drm
        JOIN db_type src_dt     ON src_dt.id   = drm.db_id
        LEFT JOIN datatype_standard ds  ON ds.id = drm.standard_id
        LEFT JOIN datatype_mapping dm   ON dm.standard_id = drm.standard_id
        JOIN db_type dst_dt     ON dst_dt.id   = dm.db_id
    """

    def get_all(self) -> dict:
        """ดึง mapping ทั้งหมด (default fallback — ใช้ standard_type เป็น final)"""
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                # fallback: ดึงแค่ source→standard โดยไม่ filter dest
                cur.execute("""
                    SELECT
                        drm.source_type AS sql_type,
                        drm.raw_type,
                        drm.logical_type,
                        ds.standard_type AS final_type,
                        drm.db_id
                    FROM datatype_raw_mapping drm
                    JOIN db_type dt ON dt.id = drm.db_id
                    LEFT JOIN datatype_standard ds ON ds.id = drm.standard_id
                    ORDER BY drm.db_id, drm.id
                """)
                rows = cur.fetchall()
            return self._rows_to_dict(rows)
        finally:
            release_connection(conn)

    def get_by_source_db(self, source_db: str) -> dict:
        """ดึง mapping เฉพาะ source DB — ใช้ standard_type เป็น final (ไม่มี dest)"""
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT
                        drm.source_type AS sql_type,
                        drm.raw_type,
                        drm.logical_type,
                        ds.standard_type AS final_type,
                        drm.db_id
                    FROM datatype_raw_mapping drm
                    JOIN db_type dt ON dt.id = drm.db_id
                    LEFT JOIN datatype_standard ds ON ds.id = drm.standard_id
                    WHERE LOWER(dt.db_name) = LOWER(%s)
                    ORDER BY drm.id
                """, (source_db,))
                rows = cur.fetchall()
            if rows:
                return self._rows_to_dict(rows)
            return self.get_all()
        finally:
            release_connection(conn)

    def get_by_db_pair(self, source_db: str, dest_db: str) -> dict:
        """
        ดึง mapping สำหรับ source→dest DB pair
        final_type = dest SQL type จาก datatype_mapping (ต่างกันตาม dest DB)
        """
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT
                        drm.source_type     AS sql_type,
                        drm.raw_type,
                        drm.logical_type,
                        ds.standard_type,
                        dm.final_type       AS dest_type,
                        dm.has_length,
                        dm.has_precision,
                        dm.has_scale
                    FROM datatype_raw_mapping drm
                    JOIN db_type src_dt ON src_dt.id = drm.db_id
                    LEFT JOIN datatype_standard ds  ON ds.id = drm.standard_id
                    JOIN db_type dst_dt ON LOWER(dst_dt.db_name) = LOWER(%s)
                    LEFT JOIN datatype_mapping dm   ON dm.standard_id = drm.standard_id
                                                AND dm.db_id = dst_dt.id
                    WHERE LOWER(src_dt.db_name) = LOWER(%s)
                    ORDER BY drm.id
                """, (dest_db, source_db))
                rows = cur.fetchall()

            if rows:
                return self._rows_to_dict_pair(rows)

            # fallback ถ้าไม่มี mapping pair
            return self.get_by_source_db(source_db)
        finally:
            release_connection(conn)

    def get_available_db_pairs(self) -> list[dict]:
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT DISTINCT dt.db_name
                    FROM datatype_raw_mapping drm
                    JOIN db_type dt ON dt.id = drm.db_id
                    ORDER BY dt.db_name
                """)
                rows = cur.fetchall()
            dbs = [r[0] for r in rows]
            return [
                {"source_db": src, "dest_db": dst}
                for src in dbs
                for dst in dbs
                if src != dst
            ]
        finally:
            release_connection(conn)

    @staticmethod
    def _rows_to_dict(rows: list) -> dict:
        """
        สำหรับ get_all / get_by_source_db
        rows: (sql_type, raw_type, logical_type, final_type, db_id)
        final = standard_type (เหมือนกันทุก dest)
        """
        mapping = {}
        for row in rows:
            if len(row) < 4:
                continue
            sql_type, raw_type, logical_type, final_type = row[:4]
            if sql_type is None:
                continue
            key = str(sql_type).lower().strip()
            if key not in mapping:
                mapping[key] = {
                    "raw":          raw_type,
                    "logical":      logical_type,
                    "final":        final_type,   # standard type
                    "dest_final":   None,          # ไม่มี dest context
                }
        return mapping

    @staticmethod
    def _rows_to_dict_pair(rows: list) -> dict:
        """
        สำหรับ get_by_db_pair
        rows: (sql_type, raw_type, logical_type, standard_type, dest_type,
               has_length, has_precision, has_scale)
        final     = standard_type (Avro/Confluent)
        dest_final = dest SQL type จริง
        """
        mapping = {}
        for row in rows:
            if len(row) < 5:
                continue
            sql_type, raw_type, logical_type, standard_type, dest_type = row[:5]
            has_length = row[5] if len(row) > 5 else False
            has_precision = row[6] if len(row) > 6 else False
            has_scale = row[7] if len(row) > 7 else False

            if sql_type is None:
                continue
            key = str(sql_type).lower().strip()
            if key not in mapping:
                mapping[key] = {
                    "raw": raw_type,
                    "logical": logical_type,
                    "final": standard_type,
                    "dest_final": dest_type,
                    "has_length": has_length,
                    "has_precision": has_precision,
                    "has_scale": has_scale,
                }
        return mapping
