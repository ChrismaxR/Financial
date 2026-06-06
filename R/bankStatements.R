library(tidyverse)

# Get data -------------------
## Bankafschriften handmatig downloaden van de portalen van de banken

## ABN data --------------
abn_data <- fs::dir_ls(
  here::here("sources", "raw_data"),
  regexp = ".TAB$"
)

rabo_data <- fs::dir_ls(
  here::here("sources", "raw_data"),
  regexp = Sys.getenv("rabo_csv")
)

transactieDataReaderABN <- function(x) {
  abn_names <- c(
    "rekeningnummer",
    "muntsoort",
    "transactiedatum",
    "beginsaldo",
    "eindsaldo",
    "rentedatum",
    "transactiebedrag",
    "omschrijving"
  )

  readr::read_delim(
    file = x,
    delim = "\t",
    col_names = FALSE,
    locale = locale(decimal_mark = ",", grouping_mark = "."),
    col_types = cols(
      X1 = col_character(),
      X2 = col_character(),
      X3 = col_character(),
      X4 = col_double(),
      X5 = col_double(),
      X6 = col_character(),
      X7 = col_double(),
      X8 = col_character()
    )
  ) |>
    setNames(abn_names)
}


abn <- map_df(
  .x = abn_data,
  .f = transactieDataReaderABN
)

## Rabo data --------------
transactieDataReaderRABO <- function(x) {
  read_csv(
    file = x,
    col_names = T,
    locale = locale(decimal_mark = ",", grouping_mark = ".")
  ) |>
    janitor::clean_names() |>
    transmute(
      rekeningnummer = iban_bban,
      muntsoort = munt,
      transactiedatum = datum,
      eindsaldo = saldo_na_trn,
      rentedatum = rentedatum,
      transactiebedrag = bedrag,
      omschrijving = omschrijving_1,
      tegenpartij = naam_tegenpartij,
      type = case_when(
        # mapping van rabo website gehaald.
        code == "ba" ~ "Pinautomaat",
        code == "bc" ~ "Pinautomaat",
        code == "bg" ~ "Overboeking",
        code == "cb" ~ "Overboeking",
        code == "db" ~ "Overboeking",
        code == "ei" ~ "Incasso",
        code == "ga" ~ "Geldautomaat",
        code == "id" ~ "iDeal",
        code == "tb" ~ "Eigen rekening",
        T ~ "Overig"
      )
    )
}

rabo <- map_df(
  .x = rabo_data,
  .f = transactieDataReaderRABO
)

# Wrangle -------------------

abn_wrangle <- abn |>
  mutate(
    richting = if_else(transactiebedrag < 0, "Af", "Bij"),
    transactiedatum = lubridate::ymd(transactiedatum),
    rentedatum = lubridate::ymd(rentedatum),
    rapportdatum = if_else(
      str_detect(str_to_lower(omschrijving), "salaris"),
      lubridate::floor_date(transactiedatum, "month"),
      as.Date(NA)
    ),
    type = case_when(
      str_starts(omschrijving, "ABN AMRO Bank N.V.") ~ "Bank servicekosten",
      str_starts(omschrijving, "BEA, Apple Pay") ~ "Apple Pay",
      str_starts(omschrijving, "BEA, Betaalpas") ~ "Betaalpas",
      str_starts(omschrijving, "GEA, Betaalpas") ~ "Pinautomaat",
      str_starts(omschrijving, "BEA") ~ "Overig",
      str_starts(omschrijving, "SEPA iDEAL") ~ "iDeal",
      str_starts(omschrijving, "SEPA Incasso") ~ "Incasso",
      str_detect(omschrijving, "^/TRTP/SEPA OVERBOEKING") ~ "Overboeking",
      str_detect(omschrijving, "^/TRTP/SEPA Incasso") ~ "Incasso",
      str_detect(omschrijving, "^/TRTP/iDEAL") ~ "iDeal",
      TRUE ~ "Overig"
    ),
    tegenpartij = case_when(
      str_starts(omschrijving, "BEA") ~
        str_match(omschrijving, "BEA, .+?\\s{2,}(.+?),PAS")[, 2],
      str_detect(omschrijving, "Naam:") ~
        str_trim(str_extract(omschrijving, "(?<=Naam: ).+?(?=\\s{2,})")),
      str_detect(omschrijving, "/NAME/") ~
        str_extract(omschrijving, "(?<=/NAME/).+?(?=/)"),
      TRUE ~ "ABN AMRO"
    ),
    categorie = case_when(
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_boodschappen")
      ) ~ "Boodschappen",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_zorgkosten")
      ) ~ "Zorgkosten",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_creditcard")
      ) ~ "Creditcard",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_huisrekening")
      ) ~ "Huisrekening",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_intern")
      ) ~ "Intern",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_filantropie")
      ) ~ "Filantropie",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_abonnement")
      ) ~ "Abonnement",
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("abn_werk")
      ) ~ "Werk",
      TRUE ~ "Overig"
    )
  ) |>
  arrange(transactiedatum) |>
  fill(rapportdatum, .direction = "down") |>
  mutate(
    rapportym = format(rapportdatum, "%Y%m")
  ) |>
  # gooi records weg van transacties die voor de eerste rapportmaand zitten
  filter(!is.na(rapportdatum))

rabo_wrangle <- rabo |>
  mutate(
    richting = if_else(transactiebedrag < 0, "Af", "Bij"),
    rapportdatum = if_else(
      day(transactiedatum) >= 21,
      floor_date(transactiedatum %m+% months(1), "month"),
      floor_date(transactiedatum, "month")
    ),
    rapportym = format(rapportdatum, "%Y%m"),
    categorie = case_when(
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_boodschappen")
      ) ~ "Boodschappen", # Boodschappen — supermarkten, bakkers, kaas/vis/delicatessen
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_afhalen")
      ) ~ "Afhalen & dineren", # Afhalen & dineren — restaurants, cafés, fastfood, bezorging, kantine
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_kleding")
      ) ~ "Kleding", # Kleding — kleding, schoenen, sportkleding
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_vaste_kosten")
      ) ~ "Vaste kosten", # Vaste kosten — nutsvoorzieningen, verzekeringen, bank
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_huisonderhoud")
      ) ~ "Huisonderhoud", # kosten in en om het huis
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_contributie")
      ) ~ "Contributie", # Contributie — verenigingen, goede doelen, kinderopvang, school
      str_detect(
        str_to_lower(tegenpartij),
        Sys.getenv("rabo_belastingen")
      ) ~ "Belastingen", # Belastingen — gemeentelijke heffingen, enz
      tegenpartij == Sys.getenv("rabo_ik") ~ "Chris",
      tegenpartij == Sys.getenv("rabo_cel") ~ "Cel",
      tegenpartij == Sys.getenv("rabo_kinderbijslag") ~ "Kinderbijslag",
      TRUE ~ "Overig"
    )
  )

# Join data sets

banktransacties <- bind_rows(abn_wrangle, rabo_wrangle) |>
  mutate(
    rekening = case_when(
      str_detect(rekeningnummer, Sys.getenv("huisreknr")) ~ "Huis",
      str_detect(rekeningnummer, Sys.getenv("persoonlijkereknr")) ~ "Chris",
      TRUE ~ "Onbekend"
    )
  )

# Aggregate -------------------

maandelijkse_cat_long <- banktransacties |>
  tidylog::filter(
    # belastingteruggave geneuzel wegfilteren, want vernaggelt de viz
    !str_detect(str_to_lower(omschrijving), ("teruggave|teruggaaf"))
  ) |>
  summarise(
    result = sum(transactiebedrag, na.rm = T),
    .by = c(rekening, rapportym, rapportdatum, categorie, richting)
  )

# Check -------------------

maandelijkse_cat_long |>
  #filter(categorie != "Intern") |>
  summarise(
    result = sum(result, na.rm = T),
    .by = c(rekening, rapportym)
  ) # |> View()

maandelijkse_cat_long |>
  #filter(categorie != "Intern") |>
  summarise(
    result = sum(result, na.rm = T)
  )

maandelijkse_cat_long |>
  pivot_wider(names_from = categorie, values_from = result)
