source(here::here("R", "inkomsten.R"))

fin_wide |> 
  group_by(jaar) |> 
  summarise(
    avg_netto = mean(netto_salaris),
    avg_inzet = mean(inzet), 
    avg_uurloon = avg_netto/avg_inzet
  ) |>
  arrange(desc(jaar)) |> 
  mutate(
    nett_delta_abs = avg_netto - lead(avg_netto),
    nett_delta_rel = scales::percent(
      (avg_netto - lead(avg_netto)) / lead(avg_netto)
    ), 
    uurloon_delta_rel = scales::percent(
      (avg_uurloon - lead(avg_uurloon)) / lead(avg_uurloon)
    ), 


  )
