source(here::here("code", "inkomsten.R"))

fin_wide

glimpse(fin_wide)

fin_model_data <- fin_wide |> 
  transmute(
    datum, 
    billable_hours_vorige_maand,
    billable_perc_vorige_maand,
    variabel_inkomen_perc,
    vakantieverlof,
    netto_salaris, 
    bruto_salaris = salaris - ouderschapsverlof + onkosten + urenbonus + tariefbonus + vakantiebijslag + vakantiebijslagbonus
  ) |> 
  filter(
    !datum %in% c("2024-07-01", "2024-08-01") # fout in de urenregistratie, waardoor verloning niet klopte
  )

model1 <- lm(bruto_salaris ~ billable_perc_vorige_maand, data = fin_model_data)

model2 <- lm(
  bruto_salaris ~ 
    billable_perc_vorige_maand + 
    variabel_inkomen_perc +
    vakantieverlof, 
  data = fin_model_data
)

fin_model_data$voorspelling_model1 <- predict(model1)
fin_model_data$voorspelling_model2 <- predict(model2)

fin_model_data |> 
ggplot(aes(x = bruto_salaris, y = voorspelling_model1)) +
  geom_point() +
    geom_abline(slope = 1, intercept = 0, color = "red") +
      labs(x = "Werkelijk bruto salaris", y = "Voorspeld bruto salaris",
    title = "Model 1: Voorspelde vs. werkelijke waarden")

fin_model_data |> 
ggplot(aes(x = bruto_salaris, y = voorspelling_model2)) +
  geom_point() +
    geom_abline(slope = 1, intercept = 0, color = "red") +
      labs(x = "Werkelijk bruto salaris", y = "Voorspeld bruto salaris",
    title = "Model 2: Voorspelde vs. werkelijke waarden")


# Evalueer modellen

summary(model1)
summary(model2)

