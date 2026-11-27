---
title:
---

<Dropdown
    name=geselecteerd_jaar
    data={jaar_selector}
    value=jaar
    multiple=true
    selectAllByDefault=true
/>

<Grid cols=3>
  <BigValue
    data={tot_res_bigvalue}
    value=totaal
    title='Resultaat in- en uitgaven'
    fmt=eur
  />

  <BigValue
    data={intern_res_bigvalue}
    value=intern_totaal
    title='Resultaat Interne overboekingen'
    fmt=eur
  />
  
  <BigValue
    data={grootste_cat_bigvalue}
    value=resultaat
    title={`Grootste uitgave: ${grootste_cat_bigvalue?.[0]?.categorie ?? ''}`}
    fmt=eur
  />

</Grid>

<BarChart
  data={maandelijks_uitgaven}
  title='Maandelijks uitgaven per categorie'
  y=result
  x=rapportdatum
  yFmt=eur
  series=categorie
  seriesOrder={['Huisrekening', 'Boodschappen', 'Zorgkosten', 'Filantropie', 'Abonnementen', 'Creditcard', 'Intern', 'Overig']}
  labels=true
  stackTotalLabel=false
/>

<BarChart
  data={maandelijks_inkomsten}
  title='Maandelijks inkomsten per categorie'
  y=result
  x=rapportdatum
  yFmt=eur
  series=categorie
  seriesOrder={['Huisrekening', 'Boodschappen', 'Zorgkosten', 'Filantropie', 'Abonnementen', 'Creditcard', 'Intern', 'Overig']}
  labels=true
  stackTotalLabel=false
/>


<LineChart
  data={resultaat}
  title='Maandelijks resultaat'
  y=resultaat
  x=rapportdatum
  yFmt=eur
  markers=true
  labels=true
  markerShape=emptyCircle
/>



```sql jaar_selector
  select distinct extract(year from rapportdatum) jaar
    from financial_data.maandelijkse_cat_long
   where rekening = 'Chris'
order by jaar desc
```

```sql tot_res_bigvalue
select sum(result) totaal
  from financial_data.maandelijkse_cat_long
 where extract(year from rapportdatum) in ${inputs.geselecteerd_jaar.value}
   and rekening = 'Chris'
```

```sql intern_res_bigvalue
select sum(result) intern_totaal
  from financial_data.maandelijkse_cat_long
 where extract(year from rapportdatum) in ${inputs.geselecteerd_jaar.value}
   and categorie = 'Intern'
   and rekening = 'Chris'
```

```sql grootste_cat_bigvalue
  select categorie,
         sum(result) resultaat
    from financial_data.maandelijkse_cat_long
   where extract(year from rapportdatum) in ${inputs.geselecteerd_jaar.value}
     and categorie not in ('Huisrekening', 'Werk')
     and rekening = 'Chris'
group by categorie 
order by resultaat
   limit 1 -- top 1 selecteren
```


```sql maandelijks_uitgaven
select *
  from financial_data.maandelijkse_cat_long
 where extract(year from rapportdatum) in ${inputs.geselecteerd_jaar.value}
   and richting = 'Af'
   and rekening = 'Chris'

```

```sql maandelijks_inkomsten
select *
  from financial_data.maandelijkse_cat_long
 where extract(year from rapportdatum) in ${inputs.geselecteerd_jaar.value}
   and richting == 'Bij'
   and rekening = 'Chris'

```

```sql resultaat
  select rapportdatum,
         sum(result) as resultaat
    from financial_data.maandelijkse_cat_long
   where extract(year from rapportdatum) in ${inputs.geselecteerd_jaar.value}
     and rekening = 'Chris'
group by rapportdatum
```