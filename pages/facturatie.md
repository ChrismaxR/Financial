---
title: Entrador
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
    data={bottom_line_totaal} 
    value=factuurbedrag
    title="Totaal gefactureerd"
    fmt=eur
  />

  <BigValue 
    data={bottom_line_totaal} 
    value=max_uurtarief
    title="Maximale uurtarief"
    fmt=eur
  />

  <BigValue 
    data={total_bruto} 
    value=bruto_bedrag
    title="Totaal Bruto verdiend"
    fmt=eur
  />


</Grid>

<BarChart
    data={bottom_line}
    title='Gefactureerde bedragen'
    x=gewerkte_y
    y=bottom_line
    type=stacked
    series=eind_klant
    yFmt=eur1
    sort =False
    stackTotalLabel=false
    labels=true
        colorPalette={[
        '#009fd9',
        '#01689b',
        '#0D1A63',
        '#76D2B6',
        ]}
/>


```sql jaar_selector
select distinct
    jaar
from financial_data.fin_wide
order by jaar desc
```

```sql fin_long_year
select *
from financial_data.fin_long
where jaar in ${inputs.geselecteerd_jaar.value}
```

```sql fin_wide_year
select *
from financial_data.fin_wide
where jaar in ${inputs.geselecteerd_jaar.value}
```


```sql total_bruto
select sum(value) as bruto_bedrag 
from ${fin_long_year}
where name in (
    'salaris', 'urenbonus', 'tariefbonus', 'vakantiebijslagbonus', 'vakantiebijslag',
    'onkosten', 'mobiliteitsvergoeding',  'plaatsingsbonus', 'aanbrengbonus'
)
```

```sql total_netto
select sum(netto_salaris) as netto_bedrag, 
       sum(facturabel) as billed_hours, 
       sum(netto_salaris)/sum(facturabel) as netto_per_billed_hour
from ${fin_wide_year}
```


```sql bottom_line
select  
  gewerkte_y, 
  tussen_persoon, 
  eind_klant,
  min(gewerkte_ym) as min_datum,
  max(gewerkte_ym) as max_datum,
  max(uurtarief) as uurtarief,
  sum(uren) as facturabele_uren,
  sum(factuurbedrag) as bottom_line
 from financial_data.bottom_line
group by
 gewerkte_y, 
 tussen_persoon, 
 eind_klant
```

```sql bottom_line_totaal
select 
  sum(factuurbedrag) as factuurbedrag,
  max(uurtarief) as max_uurtarief
  
  from financial_data.bottom_line
where gewerkte_y in ${inputs.geselecteerd_jaar.value}
```
