# Bronbestanden en scripts laden ------------------
# • Laadt het dataverwerkingsscript inkomsten.R
# • Activeert DuckDB library (duckdb)

source(here::here("R", "inkomsten.R"))
library(duckdb)
insert_time <- Sys.time() # tijd van het runnen van het script

# Databaseconnectie opzetten ---------------------
# • Maakt verbinding met DuckDB-database finhours.duckdb
con <- dbConnect(
  drv = duckdb(),
  dbdir = here::here(
    "sources",
    "financial_data",
    "finhours.duckdb"
  )
)

# Meta data tabel voor laatste update date bij te houden
## tabel maken om naar de database te sturen om brondata kwaliteit in de gaten te houden
source_data_meta <- map_df(
  .x = fs::dir_ls(here::here("sources", "raw_data")),
  .f = fs::file_info
) |>
  transmute(
    update_date_time = insert_time,
    path = as.character(path),
    birth_date_time = birth_time,
    acces_date_time = access_time,
    change_date_time = change_time
  )

# tabel voor checken van meta gegevens van wrangled data
wrangle_data_meta <- tibble::tibble(
  update_date_time = insert_time,
  fin_long_rows = nrow(fin_long),
  fin_long_cols = ncol(fin_long),
  fin_wide_rows = nrow(fin_wide),
  fin_wide_cols = ncol(fin_wide)
)

# Data schrijven naar DuckDB --------------------
# • Tabellen fin_long en fin_wide wegschrijven naar de database
# • Overschrijft bestaande tabellen volledig (overwrite = TRUE)

dbWriteTable(con, "fin_long", fin_long, append = F, overwrite = T)
dbWriteTable(con, "fin_wide", fin_wide, append = F, overwrite = T)
dbWriteTable(con, "bottom_line", bottom_line, append = F, overwrite = T)
dbWriteTable(
  con,
  "source_data_meta",
  source_data_meta,
  append = T,
  overwrite = F
)
dbWriteTable(
  con,
  "wrangle_data_meta",
  wrangle_data_meta,
  append = T,
  overwrite = F
)

# Data controleren --------------------------
# • Manuele controle met dbReadTable om te verifiëren of data correct geladen is

dbReadTable(conn = con, "fin_long")
dbReadTable(conn = con, "fin_wide")
dbReadTable(conn = con, "bottom_line")
dbReadTable(conn = con, "source_data_meta")
dbReadTable(conn = con, "wrangle_data_meta")

# Databaseconnectie sluiten -------------------
# • Sluit de verbinding met DuckDB na afronding werkzaamheden

dbDisconnect(con)

# Rscript voor create tables in het schema -----------------
# source(here::here("code", "duckdb_utils.R"))
