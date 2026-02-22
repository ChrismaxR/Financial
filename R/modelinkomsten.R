source(here::here("R", "inkomsten.R"))

# Doel van dit script:
# 1) Een eenvoudig salaris-model bouwen op basis van variabelen uit vorige maand.
# 2) Een complexer model vergelijken met extra verklarende variabelen.
# 3) Verkennen bij hoeveel gewerkte uren netto-opbrengst per uur maximaal is.

# Maak een compacte modeldataset met alleen de kolommen die nodig zijn.
# `bruto_salaris` wordt hier opnieuw opgebouwd uit de salariscomponenten.
fin_model_data <- fin_wide |>
  transmute(
    datum,
    facturabel,
    facturabel_perc_gewerkte_ym,
    variabel_inkomen_perc,
    vakantieverlof,
    netto_salaris,
    bruto_salaris = salaris -
      ouderschapsverlof +
      onkosten +
      urenbonus +
      tariefbonus +
      vakantiebijslag +
      vakantiebijslagbonus
  ) |>
  filter(
    # Deze maanden worden uitgesloten door fouten in urenregistratie/verloning.
    !datum %in% c("2024-07-01", "2024-08-01") # fout in de urenregistratie, waardoor verloning niet klopte
  )

# Basismodel: verklaar bruto salaris alleen vanuit billable percentage vorige maand.
model1 <- lm(bruto_salaris ~ facturabel_perc_gewerkte_ym, data = fin_model_data)

# Uitgebreid model: voeg variabel inkomen en vakantieverlof toe.
model2 <- lm(
  bruto_salaris ~
    facturabel_perc_gewerkte_ym +
    variabel_inkomen_perc +
    vakantieverlof,
  data = fin_model_data
)

# Voeg voorspellingen toe aan de dataset om modellen visueel te vergelijken.
# `predict(modelX)` gebruikt standaard dezelfde data als in het model (`fin_model_data`).
fin_model_data$voorspelling_model1 <- predict(model1)
fin_model_data$voorspelling_model2 <- predict(model2)

# Visual check model 1:
# Hoe dichter punten op de rode diagonaal liggen, hoe beter voorspelling ~ werkelijkheid.
fin_model_data |>
  ggplot(aes(x = bruto_salaris, y = voorspelling_model1)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, color = "red") +
  labs(
    x = "Werkelijk bruto salaris",
    y = "Voorspeld bruto salaris",
    title = "Model 1: Voorspelde vs. werkelijke waarden"
  )

# Visual check model 2 (zelfde interpretatie als model 1-plot).
fin_model_data |>
  ggplot(aes(x = bruto_salaris, y = voorspelling_model2)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, color = "red") +
  labs(
    x = "Werkelijk bruto salaris",
    y = "Voorspeld bruto salaris",
    title = "Model 2: Voorspelde vs. werkelijke waarden"
  )


# Evalueer modellen

# Bekijk o.a. R^2, significantie van coefs en residuen per model.
summary(model1)
summary(model2)

# optimum inkomsten vs uren ---------------

library(dplyr)
library(lubridate)

# Bouw maandniveau dataset:
# - `netto`: totaal netto salaris per maand
# - `uren`: facturabele uren per maand (hier wordt uitgegaan van 1 waarde per `ym`)
# - `netto_per_uur`: efficiëntiemaat voor de optimalisatie
df_month <- fin_wide %>%
  group_by(ym) %>%
  summarise(
    netto = sum(netto_salaris, na.rm = TRUE),
    uren = facturabel
  ) %>%
  ungroup() %>%
  filter(uren > 0) %>%
  mutate(
    netto_per_uur = netto / uren
  )

# Eerste verkenning: ruwe relatie uren vs netto per uur, plus loess-trendlijn.
ggplot(df_month, aes(x = uren, y = netto_per_uur)) +
  geom_point() +
  geom_smooth(method = "loess", se = FALSE) +
  labs(
    title = "Netto inkomen per uur vs gewerkte uren",
    x = "Uren per maand",
    y = "Netto per uur"
  )

library(mgcv)

# Fit een flexibele (niet-lineaire) curve om de trend te modelleren.
model <- gam(netto_per_uur ~ s(uren), data = df_month)

# Maak een fijn raster van uren om de curve soepel te evalueren.
grid <- data.frame(
  uren = seq(min(df_month$uren), max(df_month$uren), length.out = 200)
)

# Voorspel netto_per_uur voor elk punt op het raster.
grid$pred <- predict(model, newdata = grid)

# Neem het rasterpunt met hoogste voorspelde netto_per_uur als optimum.
optimum <- grid %>%
  slice_max(pred, n = 1)

optimum

# Eindplot: punten + gemodelleerde curve + verticale lijn op optimaal urenpunt.
ggplot(df_month, aes(x = uren, y = netto_per_uur)) +
  geom_point() +
  geom_line(data = grid, aes(x = uren, y = pred), color = "blue") +
  geom_vline(xintercept = optimum$uren, linetype = "dashed") +
  labs(
    title = "Optimale uren per maand",
    subtitle = paste("Optimum:", round(optimum$uren, 1), "uur"),
    x = "Uren",
    y = "Netto per uur"
  )
