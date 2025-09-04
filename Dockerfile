FROM postgres:15-alpine

# Environment variables for the default Postgres super-user
ENV POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=postgres \
    POSTGRES_DB=highstreet

# Expose the default Postgres port
EXPOSE 5432

# No further commands are necessary – the official image entrypoint launches Postgres
