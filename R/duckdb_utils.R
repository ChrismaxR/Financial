library(duckdb)

# Rscript voor create tables in het schema
# source(here::here("code", "duckdb_utils.R"))

# duckdb inserts voor Evidence dashboard

## set up database connectie
con <- dbConnect(
  drv = duckdb::duckdb(),
  dbdir = here::here(
    "sources",
    "financial_data",
    "finhours.duckdb"
  )
)

# source: https://r.duckdb.org

## set up duckdb tables
### fin_long:
dbExecute(
  con,
  "CREATE TABLE fin_long (
    jaar  TEXT,
    maand TEXT,
    ym    TEXT,
    datum DATE,
    gewerkte_ym TEXT,
    gewerkte_datum DATE,
    name  TEXT,
    value DOUBLE,
    name_filter TEXT 
  )"
)

## fin_wide:
dbExecute(
  con,
  "CREATE TABLE fin_wide (
    jaar TEXT,
    maand TEXT,
    ym TEXT,
    datum DATE,
    gewerkte_ym TEXT,
    gewerkte_datum DATE,
    stamsalaris DOUBLE,
    salaris DOUBLE,
    loonheffing DOUBLE,
    ouderschapsverlof DOUBLE,
    urenbonus DOUBLE,
    tariefbonus DOUBLE,
    vakantiebijslag DOUBLE,
    vakantiebijslagbonus DOUBLE,
    leaseauto DOUBLE,
    pensioen DOUBLE,
    netto_salaris DOUBLE,
    onkosten DOUBLE,
    mobiliteitsvergoeding DOUBLE,
    dagengewerkt DOUBLE,
    aanbrengbonus DOUBLE,
    plaatsingsbonus DOUBLE,
    inhoudingen DOUBLE,
    gratificatie DOUBLE,
    inhouding_pensioen DOUBLE,
    bruto_variabel_inkomen DOUBLE,
    bruto_normaal_variabel_inkomen DOUBLE,
    bruto_vast_inkomen DOUBLE,
    variabel_inkomen_perc DOUBLE,
    urenbonus_inkomen_perc DOUBLE,
    tariefbonus_inkomen_perc DOUBLE,
    pensioen_perc DOUBLE,
    facturabel DOUBLE,
    niet_facturabel DOUBLE,
    facturabel_perc_gewerkte_ym DOUBLE,
    educatie DOUBLE,
    part_time DOUBLE,
    vakantieverlof DOUBLE,
    inzet DOUBLE,
    intern_overleg DOUBLE,
    bijzonder_verlof DOUBLE,
    nationale_feestdag DOUBLE,
    ziek DOUBLE,
    betaald_ouderschapsverlof DOUBLE,
    onbetaald_ouderschapsverlof DOUBLE,
    dokter_tandarts DOUBLE
  )"
)

# source_data_meta
dbExecute(
  con,
  "CREATE TABLE source_data_meta (
    update_date_time  DATETIME,
    path  TEXT,
    birth_date_time DATETIME,
    acces_date_time DATETIME,
    change_date_time DATETIME
  )"
)

# wrangle_data_meta
dbExecute(
  con,
  "CREATE TABLE wrangle_data_meta (
    update_date_time DATETIME,  
    fin_long_rows INTEGER,
    fin_long_cols INTEGER,
    fin_wide_rows INTEGER,
    fin_wide_cols INTEGER
  )"
)

# Remove tables
# duckdb::dbRemoveTable(con, "fin_wide")
