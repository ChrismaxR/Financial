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



<BarChart
    data={hours_breakdown}
    title='# Uren per uursoort per maand'
    x=gewerkte_datum
    y=hours
    series=name_filter
    seriesOrder={['Inzet', 'Educatie', 'Ouderschapsverlof (betaald)', 'Ouderschapsverlof (onbetaald)', 'Dokter/Tandarts', 'Intern overleg', 'Bijzonder verlof', 'Nationale feestdag', 'Vakantieverlof', 'Ziek']}
    yFmt=num0
/>


<LineChart
    data={fin_data_wide}
    title='% Declarabel per maand'
    x=gewerkte_datum
    y=facturabel_perc_gewerkte_ym
    yFmt=pct0
    markers=true
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
select 
    jaar
from financial_data.fin_wide

group by 1
```

```sql hours_breakdown

select gewerkte_datum,
  	   name_filter, 
       sum(value) as hours
  
 from financial_data.fin_long
where 1=1 
and name_filter != 'No filter'
and value > 0
and extract(year from gewerkte_datum) in ${inputs.geselecteerd_jaar.value}

group by 
   gewerkte_datum, 
   name_filter
  
order by 
   gewerkte_datum, 
   name_filter


```

```sql fin_data_wide
select * from financial_data.fin_wide
where extract(year from gewerkte_datum) in ${inputs.geselecteerd_jaar.value}
```

```sql bill_avg
select avg(facturabel) as bill_avg,
       avg(facturabel_perc_gewerkte_ym) as bill_perc_avg 
  from financial_data.fin_wide
 where 1=1
 and jaar in ${inputs.geselecteerd_jaar.value}
and datum < (SELECT MAX(datum) FROM financial_data.fin_wide)
```