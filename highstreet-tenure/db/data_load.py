import os
from datetime import datetime, date
from typing import Dict, Optional
import math
import json

import numpy as np
import pandas as pd
from sqlalchemy import JSON, Column, DateTime, Integer, MetaData, String, Table, create_engine, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.engine import Engine

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://postgres:postgres@localhost:5432/highstreet")
CSV_FILE_MAP = {
    "new_businesses_consolidated.csv": "new_businesses",
    "accounts_closed_consolidated.csv": "accounts_closed",
    "accounts_relief_consolidated.csv": "accounts_relief",
    "accounts_no_relief_consolidated.csv": "accounts_no_relief",
    "filename_map.csv": "filename_mapping",
}


metadata = MetaData()

# Table definitions – one table per dataset category
TABLES: Dict[str, Table] = {}
for table_name in [
    "new_businesses",
    "accounts_closed",
    "accounts_relief",
    "accounts_no_relief",
    "filename_mapping",
]:
    TABLES[table_name] = Table(
        table_name,
        metadata,
        Column("id", Integer, primary_key=True, autoincrement=True),
        Column("source_file", String, nullable=False),
        Column("loaded_at", DateTime, nullable=False, server_default=text("now()")),
        Column("data", JSONB, nullable=False),
        schema="public",
    )


def get_engine(echo: bool = False) -> Engine:
    """Return a SQLAlchemy engine bound to the DATABASE_URL env var."""
    return create_engine(DATABASE_URL, echo=echo, future=True)


def create_all_tables(engine: Engine) -> None:
    """Create tables in Postgres if they do not already exist."""
    metadata.create_all(engine)


def truncate_tables(engine: Engine, table_names=None) -> None:
    """Truncate specified tables (or all managed tables if None)."""
    table_names = table_names or TABLES.keys()
    with engine.begin() as conn:
        for tbl in table_names:
            conn.execute(text(f"TRUNCATE TABLE public.{tbl} RESTART IDENTITY CASCADE"))


def _clean_value_for_json(value):
    """Ensure value is JSON-safe: convert NaN/NA to None and ISO-format dates."""
    # Handle pandas/NumPy missing
    if value is None:
        return None
    if value is pd.NA:
        return None
    if isinstance(value, float) and math.isnan(value):
        return None
    if isinstance(value, (np.floating,)) and np.isnan(value):
        return None
    if value is pd.NaT:
        return None

    # ISO-format dates
    if isinstance(value, (pd.Timestamp, datetime, date)):
        return value.isoformat()

    # Handle textual 'NaN' / 'NaT'
    if isinstance(value, str) and value.strip().lower() in {"nan", "nat"}:
        return None

    return value


def _normalize_df_for_json(df: pd.DataFrame) -> pd.DataFrame:
    """Apply JSON cleaning to all dataframe values."""
    df = df.copy()
    return df.applymap(_clean_value_for_json)


def insert_dataframe(engine: Engine, table_name: str, df: pd.DataFrame, default_source: Optional[str] = None) -> None:
    """Insert a dataframe into the given table serializing each row to JSONB.

    If the dataframe lacks a 'source_file' column, use 'default_source' instead.
    """
    if table_name not in TABLES:
        raise ValueError(f"Unknown table '{table_name}'. Allowed: {list(TABLES)}")

    if "source_file" not in df.columns:
        if default_source is None:
            raise ValueError("Dataframe must contain a 'source_file' column or provide default_source.")
        df = df.copy()
        df["source_file"] = default_source

    # Normalize to ensure valid JSON (no NaN/NaT, proper datetime strings)
    df = _normalize_df_for_json(df)

    records = []
    for _, row in df.iterrows():
        # Convert to dict and clean each value individually
        payload = {}
        for col, val in row.drop("source_file").items():
            payload[col] = _clean_value_for_json(val)
        records.append({"source_file": row["source_file"], "data": payload})

    with engine.begin() as conn:
        conn.execute(TABLES[table_name].insert(), records)





def load_from_csv_dir(engine: Engine, csv_dir: str) -> None:
    """Load CSV files from a directory into corresponding tables.
    - csv_dir: directory containing consolidated CSV files
    """
    csv_dir = os.path.abspath(csv_dir)
    for filename, table_name in CSV_FILE_MAP.items():
        path = os.path.join(csv_dir, filename)
        if not os.path.exists(path):
            continue
        df = pd.read_csv(path)
        insert_dataframe(engine, table_name, df, default_source=filename)
        print(f"Inserted {len(df)} rows from {filename} into {table_name}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Create tables and load data into Postgres.")
    parser.add_argument("--truncate", action="store_true", help="Truncate tables before inserting data")
    parser.add_argument(
        "--csv-dir",
        help="Path to directory containing consolidated CSV files to load.",
    )
  
    args = parser.parse_args()

    engine = get_engine()
    create_all_tables(engine)

    if args.truncate:
        truncate_tables(engine)


    if args.csv_dir:
        load_from_csv_dir(engine, args.csv_dir)
        print("✅ Data loaded successfully from CSV directory.")
    

