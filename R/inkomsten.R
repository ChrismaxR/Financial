library(tidyverse)
source(here::here("R", "proj_variables.R")) # aparte file om persoonlijke data niet in github repo te zetten
# Inlezen datasets -----------------------
# • Financiële data (fin_data) uit financial.csv
# • Urenregistratie (hours) uit meerdere CSV-bestanden (TimeChimp exports)

# Manuele invoer van loonstrook cijfers uit Nmbrs ESS app.
fin_data <- read_csv(fin_data_csv)

# Export van uren opgegeven in TimeChimp
hours <- map_df(
  .x = fs::dir_ls(hours_data_csv, regex = "time_export"),
  .f = read_csv
)

# Financiële data (fin) verwerking -----------------------
# • Nieuwe datumkolommen: jaar-maand (ym), eerste dag van maand (datum)
# • Berekenen verschillende variabele inkomenscomponenten (urenbonus, tariefbonus, etc.)
# • Berekenen percentage variabel inkomen en pensioenpercentage
# • Selectie en ordening relevante kolommen

fin <- fin_data |>
  mutate(
    jaar = as.character(jaar),
    ym = str_c(jaar, maand),
    datum = lubridate::ymd(str_c(jaar, maand, "01")),
    bruto_variabel_inkomen = urenbonus +
      tariefbonus +
      vakantiebijslagbonus +
      aanbrengbonus +
      plaatsingsbonus,
    bruto_normaal_variabel_inkomen = urenbonus +
      tariefbonus +
      vakantiebijslagbonus,
    bruto_vast_inkomen = salaris - bruto_variabel_inkomen,
    variabel_inkomen_perc = bruto_variabel_inkomen / salaris,
    urenbonus_inkomen_perc = urenbonus / salaris,
    tariefbonus_inkomen_perc = tariefbonus / salaris,
    pensioen_perc = (pensioen + inhouding_pensioen) / netto_salaris
  ) |>
  select(jaar, maand, ym, datum, everything())

# Urenregistratie verwerking (billed_hours_cleaned) ------------------------
# • Opschonen kolomnamen
# • Toevoegen kolom voor declarabele/niet-declarabele uren (billable)
# • Omzetten gewerkte datum naar verloonde datum (eerste dag volgende maand)
# • Toevoegen jaar-maand kolommen (verloonde_ym, gewerkte_ym)
# • Opschonen projectnamen en hernoemen datumkolom naar gewerkte_datum

billed_hours_cleaned <- hours |>
  janitor::clean_names() |>
  tidylog::mutate(
    datum = lubridate::dmy(datum),
    project = str_remove(
      project,
      hours_project_regex
    ),
    project = if_else(
      # 1 categorie maken van Onbetaald ouderschapsverlof
      project == "Onbetaald ouderschapsverlof 2025 ev",
      "Onbetaald ouderschapsverlof",
      project
    ),
    verloonde_datum = lubridate::rollforward(datum, roll_to_first = T),
    verloonde_ym = str_c(
      year(verloonde_datum),
      str_pad(
        as.character(month(verloonde_datum)),
        side = "left",
        pad = "0",
        width = 2
      )
    ),
    gewerkte_ym = str_c(
      year(datum),
      str_pad(
        as.character(month(datum)),
        side = "left",
        pad = "0",
        width = 2
      )
    ),
    uren = as.numeric(hms(uren)) / 3600,
    activiteit = case_when(
      str_detect(project, "^Inzet") ~ "Inzet",
      str_detect(
        project,
        "^Betaald ouderschapsverlof"
      ) ~ "Betaald ouderschapsverlof",
      str_detect(
        project,
        "^Onbetaald ouderschapsverlof"
      ) ~ "Onbetaald ouderschapsverlof",
      T ~ activiteit
    )
  ) |>
  rename(
    gewerkte_datum = datum
  ) |>
  arrange(gewerkte_datum)

# Aggregatie uren per project en activiteit (monthly_project_hours) ----------------------
# • Groeperen en sommeren uren per maand, project en taak
# • Activiteiten classificeren als ‘Inzet’ of specifieke taak/project
# • Omvormen naar brede dataset met activiteiten als kolommen

monthly_project_hours <- billed_hours_cleaned |>
  group_by(
    verloonde_ym,
    gewerkte_ym,
    project,
    activiteit
  ) |>
  summarise(
    uren = sum(uren, na.rm = TRUE)
  ) |>
  ungroup() |>
  transmute(
    verloonde_ym,
    gewerkte_ym,
    activiteit = if_else(
      str_detect(project, "^Inzet"),
      "Inzet",
      coalesce(activiteit, project)
    ),
    uren
  ) |>
  pivot_wider(names_from = activiteit, values_from = uren)

# Declarabele en niet-declarabele uren (billed_hours) ----------------------
# • Sommeren uren per maand naar declarabel/niet-declarabel
# • Berekenen percentage declarabele uren van de vorige maand
# • Pivot naar brede dataset

billed_hours <- billed_hours_cleaned |>
  tidylog::filter(!str_detect(activiteit, "Vakantieverlof")) |>
  group_by(verloonde_ym, gewerkte_ym, facturabel) |>
  summarise(
    uren = sum(uren, na.rm = TRUE)
  ) |>
  ungroup() |>
  pivot_wider(values_from = uren, names_from = facturabel) |>
  janitor::clean_names() |>
  mutate(
    facturabel_perc_gewerkte_ym = facturabel /
      (facturabel + if_else(is.na(niet_facturabel), 0, niet_facturabel)),
    gewerkte_datum = ymd(
      str_c(
        str_sub(gewerkte_ym, 1, 4),
        str_sub(gewerkte_ym, 5, 6),
        "01",
        sep = "-"
      )
    )
  ) |>
  select(
    verloonde_ym,
    gewerkte_ym,
    gewerkte_datum,
    everything()
  )


# Samenvoegen datasets (fin_wide) ----------------
# • Join financiële data met urenregistratie en projecturen
# • Ontbrekende waardes vervangen door 0
# • Kolommen hernoemen en opschonen met duidelijke namen

fin_wide <- fin |>
  tidylog::inner_join(billed_hours, by = c("ym" = "verloonde_ym")) |>
  inner_join(monthly_project_hours, by = c("ym" = "verloonde_ym")) |>
  mutate(
    across(
      .cols = c(
        names(
          billed_hours |> select(-c(verloonde_ym, gewerkte_ym, gewerkte_datum))
        ),
        names(
          monthly_project_hours |> select(-c(verloonde_ym, gewerkte_ym))
        )
      ),
      .fns = \(x) {
        if_else(is.na(x), 0, x)
      }
    )
  ) |>
  select(
    1:4,
    gewerkte_ym = gewerkte_ym.x,
    gewerkte_datum,
    everything(),
    -gewerkte_ym.y
  ) |>
  janitor::clean_names()

# Pivot dataset naar lang formaat (fin_long) ------------------
# • Brede dataset omvormen naar lang formaat voor verdere analyse of visualisatie

fin_long <- fin_wide |>
  pivot_longer(cols = 7:ncol(fin_wide)) |>
  mutate(
    name_filter = case_when(
      name == 'educatie' ~ "Educatie",
      name == 'vakantieverlof' ~ "Vakantieverlof",
      name == 'inzet' ~ "Inzet",
      name == 'intern_overleg' ~ "Intern overleg",
      name == 'bijzonder_verlof' ~ "Bijzonder verlof",
      name == 'nationale_feestdag' ~ "Nationale feestdag",
      name == 'ziek' ~ "Ziek",
      name == 'betaald_ouderschapsverlof' ~ "Ouderschapsverlof (betaald)",
      name == 'onbetaald_ouderschapsverlof' ~ "Ouderschapsverlof (onbetaald)",
      name == 'dokter_tandarts' ~ "Dokter/Tandarts",
      name == 'urenbonus_inkomen_perc' ~ "Urenbonus",
      name == 'tariefbonus_inkomen_perc' ~ "Tariefbonus",
      name == 'variabel_inkomen_perc' ~ "Bonus totaal",
      T ~ "No filter"
    )
  )

# Ouput -------------------------------------------------------------------

# Oud - heb eerst csv files gebruikt, maar nu overgestapt naar duckdb om beter
# controle over datatypes te houden.
# csv files voor Evidence dashboard
# write_csv(fin_wide, here::here("hours_dashboard", "sources", "data", "fin_data_wide.csv"))
# write_csv(fin_long, here::here("hours_dashboard", "sources", "data", "fin_data_long.csv"))
