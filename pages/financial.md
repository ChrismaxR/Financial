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
    data={pensioen_gespaard} 
    value=pensioen_bijdrage
    title="Totaal Pensioen gespaard"
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
        series=name
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

    <BarChart
        data={fin_data_bonus}
        title='Bonussen'
        x=datum
        y=value
        series=name
        yFmt=eur
    />

    <BarChart
        data={fin_data_long_out}
        title='Afdrachten'
        x=datum
        y=value
        series=name
        yFmt=eur
        colorPalette={[
            '#fcdad9',
            '#e88a87',
            '#eb5752',
            '#cf0d06',
        ]}
    />
</Grid>

```sql jaar_selector
select 
    jaar
from financial_data.fin_wide

group by 1
```


```sql fin_data_long_out
select * from financial_data.fin_long
where name in (
   'leaseauto', 'pensioen', 'inhoudingen', 'loonheffing', 'inhouding_pensioen'
)
and jaar in ${inputs.geselecteerd_jaar.value}
```

```sql fin_data_bonus
select * from financial_data.fin_long
where name in (
   'urenbonus', 'tariefbonus', 'vakantiebijslagbonus', 'aanbrengbonus', 'plaatsingsbonus', 'gratificatie'
)
and jaar in ${inputs.geselecteerd_jaar.value}
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

    from financial_data.fin_long
  	where name in (
        'netto_salaris', 'salaris', 'urenbonus', 'tariefbonus', 
        'vakantiebijslagbonus', 'vakantiebijslag', 'onkosten', 
        'mobiliteitsvergoeding',  'plaatsingsbonus', 'aanbrengbonus'
    )
    and jaar in ${inputs.geselecteerd_jaar.value}
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

WITH nettobruto AS (
    SELECT  
        jaar,
        maand,
        ym,
        datum,
        name, 
        CASE
            WHEN name IN ('netto_salaris') THEN 'Netto'
            ELSE 'Bruto' 
        END AS category,
        value
    FROM financial_data.fin_long
    WHERE name IN (
        'netto_salaris', 'salaris', 'urenbonus', 'tariefbonus', 
        'vakantiebijslagbonus', 'vakantiebijslag', 'onkosten', 
        'mobiliteitsvergoeding',  'plaatsingsbonus', 'aanbrengbonus'
    )
    AND jaar in ${inputs.geselecteerd_jaar.value}
),

agg1 AS (
    SELECT  
        jaar,
        maand, 
        ym,
        datum,
        category,
        SUM(value) AS summed_value
    FROM nettobruto
    GROUP BY jaar, maand, ym, datum, category
),

avg_values AS (
    SELECT 
        category, 
        AVG(summed_value) AS avg_summed_value 
    FROM agg1 
    GROUP BY category
)

SELECT * 
FROM avg_values
PIVOT (
    any_value(avg_summed_value) FOR category IN ('Netto', 'Bruto')
)
```

```sql variable_inkomen_perc
select * from financial_data.fin_long
where name in (
   'variabel_inkomen_perc'
)
and jaar in ${inputs.geselecteerd_jaar.value}

```

```sql perc_variable_inc_avg
select avg(variabel_inkomen_perc) as avg_variabel_inkomen_perc
  from financial_data.fin_wide
 where 1=1
   and jaar in ${inputs.geselecteerd_jaar.value}
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