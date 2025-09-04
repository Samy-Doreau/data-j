import os
from datetime import datetime
from typing import Dict

import pandas as pd
from sqlalchemy import JSON, Column, DateTime, Integer, MetaData, String, Table, create_engine, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.engine import Engine

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://postgres:postgres@localhost:5432/highstreet")

metadata = MetaData()

# Table definitions – one table per dataset category
TABLES: Dict[str, Table] = {}
for table_name in [
    "new_businesses",
    "accounts_closed",
    "accounts_relief",
    "accounts_no_relief",
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


def insert_dataframe(engine: Engine, table_name: str, df: pd.DataFrame) -> None:
    """Insert a dataframe into the given table serializing each row to JSONB."""
    if table_name not in TABLES:
        raise ValueError(f"Unknown table '{table_name}'. Allowed: {list(TABLES)}")

    # Expect the dataframe to have a `source_file` column (added earlier in notebook)
    if "source_file" not in df.columns:
        raise ValueError("Dataframe must contain a 'source_file' column.")

    records = [
        {"source_file": row["source_file"], "data": row.drop("source_file").to_dict()}
        for _, row in df.iterrows()
    ]

    with engine.begin() as conn:
        conn.execute(TABLES[table_name].insert(), records)


if __name__ == "__main__":
    import argparse
    import pickle

    parser = argparse.ArgumentParser(description="Create tables and optionally load pickled dataframes.")
    parser.add_argument("--truncate", action="store_true", help="Truncate tables before inserting data")
    parser.add_argument(
        "--pickle-path",
        help="Path to a pickle file containing a dict of {{table_name: dataframe}} exported from the notebook.",
    )
    args = parser.parse_args()

    engine = get_engine()
    create_all_tables(engine)

    if args.truncate:
        truncate_tables(engine)

    if args.pickle_path:
        with open(args.pickle_path, "rb") as fh:
            data: Dict[str, pd.DataFrame] = pickle.load(fh)
        for table, df in data.items():
            print(f"Inserting {len(df)} rows into {table}…")
            insert_dataframe(engine, table, df)
        print("✅ Data loaded successfully.")
