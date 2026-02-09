---
title:  
---


<Dropdown
    name=geselecteerd_jaar
    data={jaar_selector}
    value=jaar
    multiple=true
    defaultValue="2025"
/>

<Grid cols=4>
  <BigValue 
    data={hours_bigvalue} 
    value=inzet
    title="# Uren inzet"
  />

  <BigValue 
    data={hours_bigvalue} 
    value=verlof
    title="# Uren verlof"
  />

  <BigValue 
    data={hours_bigvalue} 
    value=educatie
    title="# Uren educatie"
  />

    <BigValue 
    data={hours_bigvalue} 
    value=ziek
    title="# Uren ziekte"
  />
</Grid>

<BarChart
    data={hours_breakdown}
    title='# Uren per uursoort per maand'
    x=gewerkte_datum
    y=hours
    series=name_filter
    seriesOrder={['Inzet', 'Educatie', 'Ouderschapsverlof (betaald)', 'Ouderschapsverlof (onbetaald)', 'Dokter/Tandarts', 'Intern overleg', 'Bijzonder verlof', 'Nationale feestdag', 'Vakantieverlof', 'Ziek']}
    yFmt=num0
    labels=true
    stackTotalLabel=false
/>


<LineChart
    data={fin_data_wide}
    title='% Declarabel per maand'
    x=gewerkte_datum
    y=facturabel_perc_gewerkte_ym
    yFmt=pct0
    markers=true
    labels=true
    markerShape=emptyCircle>
    <ReferenceLine
        data={bill_avg}
        y=bill_perc_avg
        label=Gem.
        color=#27445D
        labelPosition="aboveStart"
    />
</LineChart>

```sql jaar_selector
select distinct
    jaar
from financial_data.fin_wide
order by jaar desc
```

```sql fin_long_year
select *
from financial_data.fin_long
where extract(year from gewerkte_datum) in ${inputs.geselecteerd_jaar.value}
```

```sql fin_wide_year
select *
from financial_data.fin_wide
where extract(year from gewerkte_datum) in ${inputs.geselecteerd_jaar.value}
```

```sql hours_breakdown

select gewerkte_datum,
  	   name_filter, 
       sum(value) as hours
  
from ${fin_long_year}
where name_filter not in ('Bonus totaal', 'Tariefbonus', 'Urenbonus', 'No filter')
  and value > 0

group by 
   gewerkte_datum, 
   name_filter
  
order by 
   gewerkte_datum, 
   name_filter


```

```sql fin_data_wide
select * from ${fin_wide_year}
```

```sql bill_avg
select avg(facturabel) as bill_avg,
       avg(facturabel_perc_gewerkte_ym) as bill_perc_avg 
  from ${fin_wide_year}
 where datum < (SELECT MAX(datum) FROM financial_data.fin_wide)
```

```sql hours_bigvalue
select 
  sum(inzet) as inzet, 
  sum(vakantieverlof) as verlof, 
  sum(educatie) as educatie, 
  sum(ziek) as ziek
from financial_data.fin_wide
where extract(year from gewerkte_datum) in ${inputs.geselecteerd_jaar.value}

```