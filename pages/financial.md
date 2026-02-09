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
    data={total_bruto} 
    value=bruto_bedrag
    title="Totaal Bruto"
    fmt=eur
  />

  <BigValue 
    data={total_netto} 
    value=netto_bedrag
    title="Totaal Netto"
    fmt=eur
  />

  <BigValue 
    data={pensioen_gespaard} 
    value=pensioen_bijdrage
    title="Totaal Pensioen"
    fmt=eur
  />

    <BigValue 
    data={total_netto} 
    value=netto_per_billed_hour
    title="Netto per billed uur"
    fmt=eur
  />
</Grid>

<Grid cols=2>
    <LineChart
        data={brutonetto}
        title='Bruto vs. netto salaris'
        x=datum
        y=summed_value
        series=category
        yFmt=eur
        step=false
        markers=true
        markerShape=emptyCircle>
            <ReferenceLine 
                data={avg_brutonetto} 
                y=Netto 
                label="Gem. Netto" 
                color=#27445D 
                labelPosition="aboveStart"
            />
            <ReferenceLine 
                data={avg_brutonetto} 
                y=Bruto 
                label="Gem. Bruto" 
                color=#27445D 
                labelPosition="aboveStart"
            />
    </LineChart>


    <LineChart
        data={variable_inkomen_perc}
        title='% Variabel inkomen per maand'
        x=datum
        y=value
        series=name_filter
        yFmt=pct0
        markers=true
        markerShape=emptyCircle>
        <ReferenceLine
            data={perc_variable_inc_avg}
            y=avg_variabel_inkomen_perc
            label=Gem.
            color=#27445D
            labelPosition="aboveStart"
        />
    </LineChart>
</Grid>

    <BarChart
        data={fin_data_bonus}
        title='Bonussen'
        x=datum
        y=value
        series=name
        yFmt=eur
        labels=true
    />

    <BarChart
        data={fin_data_long_out}
        title='Afdrachten'
        x=datum
        y=value
        series=name
        yFmt=eur
        labels=true
        colorPalette={[
            '#fcdad9',
            '#e88a87',
            '#eb5752',
            '#cf0d06',
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


```sql fin_data_long_out
select * from ${fin_long_year}
where name in (
   'leaseauto', 'pensioen', 'inhoudingen', 'loonheffing', 'inhouding_pensioen'
)
```

```sql fin_data_bonus
select * from ${fin_long_year}
where name in (
   'urenbonus', 'tariefbonus', 'vakantiebijslagbonus', 'aanbrengbonus', 'plaatsingsbonus', 'gratificatie'
)
```

```sql brutonetto
with nettobruto as (
    select  jaar,
            maand,
            ym,
            datum,
            name, 
            case
                when name in ('netto_salaris') then 'Netto'
                else 'Bruto' 
            end as category,
            value

    from ${fin_long_year}
  	where name in (
        'netto_salaris', 'salaris', 'urenbonus', 'tariefbonus', 
        'vakantiebijslagbonus', 'vakantiebijslag', 'onkosten', 
        'mobiliteitsvergoeding',  'plaatsingsbonus', 'aanbrengbonus'
    )
)

select  jaar,
        maand, 
        ym,
        datum,
        category,
        sum(value) as summed_value
from nettobruto

group by jaar, maand, ym, datum, category

```

```sql avg_brutonetto

select
  avg(case when category = 'Netto' then summed_value end) as Netto,
  avg(case when category = 'Bruto' then summed_value end) as Bruto
from ${brutonetto}
```

```sql variable_inkomen_perc
select * from ${fin_long_year}
where name in (
   'variabel_inkomen_perc', 
   'urenbonus_inkomen_perc', 
   'tariefbonus_inkomen_perc'
)

```

```sql perc_variable_inc_avg
select avg(variabel_inkomen_perc) as avg_variabel_inkomen_perc
  from ${fin_wide_year}
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

```sql pensioen_gespaard
select sum(value) as pensioen_bijdrage
from ${fin_long_year}
where name in ('pensioen', 'inhouding_pensioen')
```
