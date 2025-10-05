db <- "highstreet"
db_host <- "127.0.0.1"
db_port <- "5432"
db_user <- "postgres"
db_password <- "postgres"

get_connection <- function() {
  dbConnect(
    RPostgres::Postgres(),
    dbname = db,
    host = db_host,
    port = db_port,
    user = db_user,
    password = db_password
  )
}
