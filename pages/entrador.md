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
    data={total_bruto} 
    value=bruto_bedrag
    title="Totaal Bruto verdiend"
    fmt=eur
  />

  <BigValue 
    data={total_netto} 
    value=netto_bedrag
    title="Totaal Netto verdiend"
    fmt=eur
  />


  <BigValue 
    data={total_netto} 
    value=netto_per_billed_hour
    title="Netto per billed uur"
    fmt=eur
  />
  
</Grid>

<BarChart
    data={bottom_line}
    title='Gefactureerde bedragen'
    x=eind_klant
    y=bottom_line
    type=stacked
    swapXY=true
    series=eind_klant
    yFmt=eur
/>


```sql jaar_selector
select 
    jaar
from financial_data.fin_wide

group by 1
```


```sql total_bruto
select sum(value) as bruto_bedrag 
 from (
  select * 
    from financial_data.fin_long
   where 1 = 1
     and name in (
        'salaris', 'urenbonus', 'tariefbonus', 'vakantiebijslagbonus', 'vakantiebijslag',
        'onkosten', 'mobiliteitsvergoeding',  'plaatsingsbonus', 'aanbrengbonus'
        )
     and jaar in ${inputs.geselecteerd_jaar.value}
 )
```

```sql total_netto
select sum(netto_salaris) as netto_bedrag, 
       sum(facturabel) as billed_hours, 
       sum(netto_salaris)/sum(facturabel) as netto_per_billed_hour
from financial_data.fin_wide

where 1=1
  and jaar in ${inputs.geselecteerd_jaar.value}
```

```sql pensioen_gespaard
select sum(value) as pensioen_bijdrage
  from financial_data.fin_long
where 1=1
  and name in ('pensioen', 'inhouding_pensioen')
  and jaar in ${inputs.geselecteerd_jaar.value}
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
select sum(factuurbedrag) as factuurbedrag
  from financial_data.bottom_line
where 1=1
  and gewerkte_y in ${inputs.geselecteerd_jaar.value}
```