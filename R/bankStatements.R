library(tidyverse)

abn_names <- c(
  "Rekeningnummer", "Muntsoort",	"Transactiedatum", 	
  "Beginsaldo",	"Eindsaldo",	"Rentedatum",
  "Transactiebedrag",	"Omschrijving"
)

abn <- readr::read_delim(
  file = "sources/raw_data/TXT260604162423.TAB",
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

tekst <- abn |> 
  filter(str_detect(Omschrijving, "^/TRTP/")) |> 
  pull(Omschrijving)


abn_wrangle <- abn |>
  mutate(
    Transactiedatum = lubridate::ymd(Transactiedatum),
    Rentedatum      = lubridate::ymd(Rentedatum),

    type = case_when(
      str_starts(Omschrijving, "BEA, Apple Pay")          ~ "pin_applepay",
      str_starts(Omschrijving, "BEA, Betaalpas")          ~ "pin_pas",
      str_starts(Omschrijving, "BEA")                     ~ "pin_overig",
      str_starts(Omschrijving, "SEPA iDEAL")              ~ "ideal",
      str_starts(Omschrijving, "SEPA Incasso")            ~ "incasso",
      str_detect(Omschrijving, "^/TRTP/SEPA OVERBOEKING") ~ "overboeking",
      str_detect(Omschrijving, "^/TRTP/SEPA Incasso")     ~ "incasso",
      str_detect(Omschrijving, "^/TRTP/iDEAL")            ~ "ideal",
      TRUE                                                 ~ "overig"
    ),

    betaalmethode = case_when(
      str_starts(Omschrijving, "BEA") ~
        str_match(Omschrijving, "BEA, (.+?)\\s{2,}")[, 2],
      TRUE ~ NA_character_
    ),

    tegenpartij = case_when(
      str_starts(Omschrijving, "BEA") ~
        str_match(Omschrijving, "BEA, .+?\\s{2,}(.+?),PAS")[, 2],
      str_detect(Omschrijving, "Naam:") ~
        str_trim(str_extract(Omschrijving, "(?<=Naam: ).+?(?=\\s{2,})")),
      str_detect(Omschrijving, "/NAME/") ~
        str_extract(Omschrijving, "(?<=/NAME/).+?(?=/)"),
      TRUE ~ NA_character_
    )
  )

