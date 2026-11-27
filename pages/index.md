---
title: Christian in 2026
hide_toc: true
hide_breadcrumbs: true
hide_sidebar: true
---

## Wat ik heb geleerd/verbeterd:

<script>
  // Aanpak: hoe een Business Analist de scenario's samen met de stakeholder uitwerkt
  const fasen = [
    { nr: 1, fase: 'Requirements -> Refinen en kwaliteit checken', wie: 'Dr. Van Dalen',
      wat: 'Dit jaar aandachtig backlogs gemanaged, refinements geleid en de nadruk gelegd op kwalitatieve producten.',
      artefact: 'Product Backlog Items, Stakeholdes, QA.' },
    { nr: 2, fase: 'Procesmodellering -> documentatie en communicatie', wie: 'COO, afdelingshoofden, HR, finance',
      wat: 'In het modelleeren ben ik preciezer en  effectiever geworden. Dit komt mijn documentatie- en communicatievaardigheden ten goede',
      artefact: 'BSC Business Proces Modelling, Enterprise Architect, scenariodefinities.' },
    { nr: 3, fase: 'Data-analyse -> BA-competentie', wie: 'datateam, Dr. Van Dalen',
      wat: 'Data gebruik ik steeds vaker als eigen analyse-instrument, zowel in mijn werk als in mijn eigen projecten. Ik vul daarmee mijn profiel als  functioneel analist verder aan. Dit zet ik nu ook bewust in voor een volgende opdracht.',
      artefact: 'Python training, SQL, datatransformatie- en visualisatie' },
  ];

  const principes = [

  ];
</script>

<div class="flex flex-col my-6">
  {#each fasen as f, i}
    <div class="flex gap-4">
      <div class="flex flex-col items-center">
        <div class="w-10 h-10 shrink-0 rounded-full bg-primary text-base-100 flex items-center justify-center text-lg font-bold">{f.nr}</div>
        {#if i < fasen.length - 1}
          <div class="w-0.5 grow bg-base-300"></div>
        {/if}
      </div>
      <div class="flex-1 rounded-md border border-base-300 border-l-4 border-l-primary bg-base-100 p-3 mb-4 flex flex-col gap-2">
        <div class="flex flex-wrap items-baseline justify-between gap-x-4">
          <span class="font-semibold leading-tight">{f.fase}</span>
        </div>
        <div class="text-sm">{f.wat}</div>
        <div class="text-sm pt-2 border-t border-base-300"><span class="font-semibold">Kernwoorden:</span> {f.artefact}</div>
      </div>
    </div>
  {/each}
</div>

<div class="flex flex-wrap gap-2 mb-8">
  {#each principes as p}
    <span class="rounded-full border border-base-300 bg-base-200 px-3 py-1 text-sm">{p}</span>
  {/each}
</div>

## Geboekte uren

<Dropdown
    name=geselecteerd_jaar
    data={jaar_selector}
    value=jaar
    multiple=true
    defaultValue={['2025', '2026']}
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
where jaar > 2021
order by jaar desc
```

```sql fin_long_year
select *
from financial_data.fin_long
where jaar > '2021'
  and jaar in ${inputs.geselecteerd_jaar.value}
```

```sql fin_wide_year
select *
from financial_data.fin_wide
where jaar in ${inputs.geselecteerd_jaar.value}
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


---

## Facturatie afgelopen 5 jaar


<Grid cols=2>
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



```sql fin_long_year_b
select *
from financial_data.fin_long
--where jaar in ${inputs.geselecteerd_jaar.value}
```

```sql fin_wide_year_b
select *
from financial_data.fin_wide
--where jaar in ${inputs.geselecteerd_jaar.value}
```


```sql total_bruto
select sum(value) as bruto_bedrag 
from ${fin_long_year}
where datum >= '2022-01-01' -- alleen bruto verdiend bij Entrador, niet eerder.
  and name in (
    'salaris', 'urenbonus', 'tariefbonus', 'vakantiebijslagbonus', 'vakantiebijslag',
    'onkosten', 'mobiliteitsvergoeding',  'plaatsingsbonus', 'aanbrengbonus'
)
```

```sql total_netto
select sum(netto_salaris) as netto_bedrag, 
       sum(facturabel) as billed_hours, 
       sum(netto_salaris)/sum(facturabel) as netto_per_billed_hour
from ${fin_wide_year_b}
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
--where gewerkte_y in ${inputs.geselecteerd_jaar.value}
```


---

## Opleidingen in 2026

<Grid cols=3>

<img src="/introPython.jpg" alt="Python" style="float: right; width: 230px; margin: 0 0 1rem 2rem;" />
<img src="/BPM.jpg" alt="ProcessModelling" style="float: right; width: 230px; margin: 0 0 1rem 2rem;" />
<img src="/Practitioner.jpg" alt="Python" style="float: right; width: 230px; margin: 0 0 1rem 2rem;" />

</Grid>



```sql fin_long_365
select *
from financial_data.fin_long
where datum > current_date - 365
```

```sql fin_wide_365
select *
from financial_data.fin_wide
where datum > current_date - 365
```

```sql fin_agg_netto
select datum, 
  		name, 
  		value,
      value - LAG(value) OVER (ORDER BY datum) as verschil
  from ${fin_long_365}
where name = 'netto_salaris'
order by datum desc
```

```sql fin_agg_bill_perc
 select datum,
  	    value,
        value - LAG(value) OVER (ORDER BY datum) as verschil
    from ${fin_long_365}
   where name = 'facturabel_perc_gewerkte_ym'
order by datum desc
```

```sql fin_variabel_inkomen_perc
 select datum,
  	    value,
        value - LAG(value) OVER (ORDER BY datum) as verschil
    from ${fin_long_365}
   where name = 'variabel_inkomen_perc'
order by datum desc
```

```sql fin_agg_bonus
select datum, 
  		name, 
  		value,
      value - LAG(value) OVER (ORDER BY datum) as verschil
  from ${fin_long_365}
where name = 'bruto_variabel_inkomen'
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
  from ${fin_wide_365}
  order by datum desc
)

select dt.*, 
       uurloon - lag(uurloon) over (order by datum) as uurloon_verschil
from dt
order by datum desc
```

```sql avg_netto
select avg(netto_salaris) as avg
from ${datatable}

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
