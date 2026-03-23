# Datakwaliteit validatie met {pointblank}
# Draait na duckdb_insert.R — tabellen fin_wide, fin_long en bottom_line
# worden gevalideerd en een HTML-rapport wordt opgeslagen.

library(pointblank)
library(DBI)
library(duckdb)
library(here)

# Databaseconnectie (read-only, na sluiten van insert-connectie) ------------
con <- dbConnect(
  drv = duckdb(),
  dbdir = here::here("sources", "financial_data", "finhours.duckdb"),
  read_only = TRUE
)

fin_wide <- dbReadTable(con, "fin_wide")
fin_long <- dbReadTable(con, "fin_long")
bottom_line <- dbReadTable(con, "bottom_line")

dbDisconnect(con)

# Gedeelde actie-niveaus: waarschuw als >1% van de rijen een check faalt ----
al <- action_levels(warn_at = 0.01)

# Agent: fin_wide -----------------------------------------------------------
agent_fin_wide <- create_agent(
  tbl = fin_wide,
  label = "fin_wide",
  actions = al
) |>
  # Verplichte kolommen aanwezig
  col_exists(
    columns = c(
      "jaar",
      "maand",
      "ym",
      "datum",
      "gewerkte_ym",
      "gewerkte_datum",
      "stamsalaris",
      "salaris",
      "loonheffing",
      "netto_salaris",
      "dagengewerkt",
      "variabel_inkomen_perc",
      "facturabel_perc_gewerkte_ym"
    )
  ) |>
  # Datatypes
  col_is_date(columns = c("datum", "gewerkte_datum")) |>
  col_is_numeric(
    columns = c(
      "stamsalaris",
      "salaris",
      "loonheffing",
      "netto_salaris",
      "dagengewerkt"
    )
  ) |>
  # Sleutelkolommen niet leeg
  col_vals_not_null(columns = vars(datum)) |>
  col_vals_not_null(columns = vars(ym)) |>
  # Salarissen positief (na_pass = TRUE: legacy data heeft geen stamsalaris)
  col_vals_gt(columns = vars(salaris), value = 0) |>
  col_vals_gt(columns = vars(loonheffing), value = 0) |>
  col_vals_gt(columns = vars(netto_salaris), value = 0) |>
  col_vals_gt(columns = vars(stamsalaris), value = 0, na_pass = TRUE) |>
  # Werkdagen per maand realistisch
  col_vals_between(columns = vars(dagengewerkt), left = 0, right = 31) |>
  # Percentages tussen 0 en 1
  col_vals_between(
    columns = vars(variabel_inkomen_perc),
    left = 0,
    right = 1
  ) |>
  col_vals_between(
    columns = vars(facturabel_perc_gewerkte_ym),
    left = 0,
    right = 1,
    na_pass = TRUE
  ) |>
  # Geen dubbele maanden
  rows_distinct(columns = vars(datum)) |>
  interrogate()

# Agent: fin_long -----------------------------------------------------------
# name_filter is een gecontroleerde waardenset (zie inkomsten.R)
known_name_filters <- c(
  "Educatie",
  "Vakantieverlof",
  "Inzet",
  "Intern overleg",
  "Bijzonder verlof",
  "Nationale feestdag",
  "Ziek",
  "Ouderschapsverlof (betaald)",
  "Ouderschapsverlof (onbetaald)",
  "Dokter/Tandarts",
  "Urenbonus",
  "Tariefbonus",
  "Bonus totaal",
  "No filter"
)

agent_fin_long <- create_agent(
  tbl = fin_long,
  label = "fin_long",
  actions = al
) |>
  col_vals_not_null(columns = vars(datum)) |>
  col_vals_not_null(columns = vars(name)) |>
  col_vals_not_null(columns = vars(value)) |>
  col_is_numeric(columns = vars(value)) |>
  col_vals_in_set(columns = vars(name_filter), set = known_name_filters) |>
  interrogate()

# Agent: bottom_line --------------------------------------------------------
agent_bottom_line <- create_agent(
  tbl = bottom_line,
  label = "bottom_line",
  actions = al
) |>
  col_vals_gt(columns = vars(uren), value = 0) |>
  col_vals_gt(columns = vars(uurtarief), value = 0) |>
  # Factuurbedrag moet overeenkomen met uren * uurtarief
  col_vals_expr(
    expr = expr(abs(factuurbedrag - (uren * uurtarief)) < 0.01)
  ) |>
  interrogate()

# Rapporten exporteren (één HTML per agent) ---------------------------------
export_report(agent_fin_wide,    filename = here::here("sources", "financial_data", "dq_fin_wide.html"))
export_report(agent_fin_long,    filename = here::here("sources", "financial_data", "dq_fin_long.html"))
export_report(agent_bottom_line, filename = here::here("sources", "financial_data", "dq_bottom_line.html"))

message("Data kwaliteitsrapporten opgeslagen in sources/financial_data/")
