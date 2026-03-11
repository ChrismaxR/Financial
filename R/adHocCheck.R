# Ad hoc check op bedragen en juiste assumpties voor legacy data.
bind_rows(
  legacy_fin |>
    mutate(
      werkgever = "Creditsafe"
    ) |>
    group_by(werkgever, jaar) |>
    summarise(
      bruto = sum(salaris),
      netto = sum(netto_salaris),
      pensioen = sum(pensioen),
      loonheffing = sum(loonheffing),
      vakantiebijslag = sum(vakantiebijslag, na.rm = T),
      ouderschapsverlof = sum(ouderschapsverlof)
    ),

  fin |>
    mutate(
      werkgever = "Entrador"
    ) |>
    group_by(werkgever, jaar = as.character(jaar)) |>
    summarise(
      bruto = sum(
        salaris +
          urenbonus +
          tariefbonus +
          vakantiebijslagbonus +
          vakantiebijslag +
          onkosten +
          mobiliteitsvergoeding +
          plaatsingsbonus +
          aanbrengbonus
      ),
      netto = sum(netto_salaris),
      pensioen = sum(pensioen),
      loonheffing = sum(loonheffing),
      vakantiebijslag = sum(vakantiebijslag + vakantiebijslagbonus),
      ouderschapsverlof = sum(ouderschapsverlof) * 0.9
    )
)
