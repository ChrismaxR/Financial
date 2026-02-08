---
title:
---

<Grid cols=3>
  <BigValue 
    data={fin_agg_netto} 
    value=value
    sparkline=datum
    sparklineType=area
    title={`Netto salaris ${update_month?.[0]?.month ?? ''}`}
    fmt=eur
    comparison=verschil
    comparisonFmt=eur
    comparisonTitle="vs. vorige maand"
  />

  <BigValue 
    data={datatable} 
    value=uurloon
    sparkline=datum
    sparklineType=area
    title={`Uurloon ${update_month?.[0]?.month ?? ''}`}
    fmt=eur2
    comparison=uurloon_verschil
    comparisonFmt=eur2
    comparisonTitle="vs. vorige maand"
  />

  <BigValue 
    data={fin_agg_bill_perc} 
    value=value
    sparkline=datum
    sparklineType=area
    title={`Billable % ${update_month?.[0]?.month ?? ''}`}
    fmt=pct1
    comparison=verschil
    comparisonFmt=pct1
    comparisonTitle="vs. vorige maand"
  />

  <BigValue 
    data={fin_agg_bonus} 
    value=value
    sparkline=datum
    sparklineType=area
    title={`Bonus % ${update_month?.[0]?.month ?? ''}`}
    fmt=eur
    comparison=verschil
    comparisonFmt=eur
    comparisonTitle="vs. vorige maand"
  />

  <BigValue 
    data={vakantieuren} 
    value=label
    title={`Vakantieverlof ${update_month?.[0]?.year ?? ''}`}
    comparison=vakantie_uren_over
    comparisonTitle="vakantieverlofuren over"
  />

  <BigValue 
    data={fin_variabel_inkomen_perc} 
    value=value
    sparkline=datum
    sparklineType=area
    title={`Variabel inkomen ${update_month?.[0]?.month ?? ''}`}
    fmt=pct1
    comparison=verschil
    comparisonFmt=pct1
    comparisonTitle="vs. vorige maand"
  />
</Grid>

<LineChart
    data={datatable}
    title='Netto Salaris Ontwikkeling'
    x=datum 
    y=netto_salaris
    yFmt=eur
    markers=true
    markerShape=emptyCircle>
    <ReferenceLine 
        data={avg_netto} 
        y=avg 
        label="Gem."
        color=#27445D
        labelPosition="aboveStart"
    />
</LineChart>


Laatste update: <Value data={update_time} column=update row=0 fmt='longdate'/>



```sql fin_agg_netto
select datum, 
  		name, 
  		value,
      value - LAG(value) OVER (ORDER BY datum) as verschil
  from financial_data.fin_long
where name = 'netto_salaris'
and datum > current_date - 365
order by datum desc
```

```sql fin_agg_bill_perc
 select datum,
  	    value,
        value - LAG(value) OVER (ORDER BY datum) as verschil
    from financial_data.fin_long
   where 1 = 1
     and name = 'facturabel_perc_gewerkte_ym'
     and datum > current_date - 365
order by datum desc
```

```sql fin_variabel_inkomen_perc
 select datum,
  	    value,
        value - LAG(value) OVER (ORDER BY datum) as verschil
    from financial_data.fin_long
   where 1 = 1
     and name = 'variabel_inkomen_perc'
     and datum > current_date - 365
order by datum desc
```

```sql fin_agg_bonus
select datum, 
  		name, 
  		value,
      value - LAG(value) OVER (ORDER BY datum) as verschil
  from financial_data.fin_long
where name = 'bruto_variabel_inkomen'
and datum > current_date - 365
order by datum desc
```


```sql datatable
with dt as (
  select ym, 
        datum,
        jaar,
        facturabel_perc_gewerkte_ym,
        facturabel, 
        bruto_variabel_inkomen,
        variabel_inkomen_perc, 
        netto_salaris, 
        netto_salaris/facturabel as uurloon
  from financial_data.fin_wide
  where datum > current_date - 365
  order by datum desc
)

select dt.*, 
       uurloon - lag(uurloon) over (order by datum) as uurloon_verschil
from dt
order by datum desc
```

```sql avg_netto
select avg(netto_salaris) as avg
from (
  select * from ${datatable}
)

```

```sql vakantieuren
with vak as (
  select substring(gewerkte_ym, 1, 4) as gewerkte_jaar, 
        maand, 
        gewerkte_ym, 
        datum, 
        Vakantieverlof
  from financial_data.fin_wide

  where gewerkte_jaar = EXTRACT(YEAR FROM CURRENT_DATE)
)

select EXTRACT(YEAR FROM CURRENT_DATE) as gewerkte_jaar,
  coalesce(sum(Vakantieverlof), 0) as vakantie_uren,
  cast(coalesce(sum(vakantieverlof), 0) as string) || ' uur' as label,
  144 - coalesce(sum(vakantieverlof), 0) as vakantie_uren_over
from vak
```

```sql update_time
select max(update_date_time) as update 
  from financial_data.source_data_meta
```

```sql update_month
select 
  strftime(max(datum), '%b %Y') as month, 
  strftime(max(datum), '%Y') as year
  from financial_data.fin_wide
```
