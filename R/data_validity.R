# Test {pointblank}, package for assessing data quality in a data pipeline
# Idea was to apply this to this project, but seems a bit overkill for now...
# You can use the pointblank package in R to assess data quality and freshness of the data coming from your CSV and DuckDB database. Below is a structured approach:

library(pointblank)

## set up database connectie
con <- dbConnect(
  drv = duckdb::duckdb(),
  dbdir = here::here(
    "hours_dashboard",
    "sources",
    "finhours",
    "finhours.duckdb"
  )
)

fin_long <- dbGetQuery(con, "SELECT * FROM fin_long")
fin_wide <- dbGetQuery(con, "SELECT * FROM fin_wide")


# Define the acceptable freshness threshold (e.g., max 1 day old)
threshold_date <- Sys.Date() - 1

# Apply the same checks for DuckDB data
agent_fin_long <- create_agent(tbl = fin_long) %>%
  col_vals_between(
    columns = vars(datum),
    left = threshold_date,
    right = Sys.Date(),
    na_pass = FALSE
  ) %>%
  col_is_date(vars(last_updated))
