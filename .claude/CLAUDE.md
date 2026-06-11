# Financial Dashboard — Project Context

Personal finance dashboard built with R (data pipeline) → DuckDB (storage) → Evidence.dev (visualization). All code is Dutch-language; variable names and comments are in Dutch.

---

## Architecture

```
Raw data (manual exports)
  ├── financial.csv          → payslip entries (NMBRS app, manually entered)
  ├── legacy_financial.csv   → payslips from previous employer
  ├── *time_export*.csv      → TimeChimp hour logs
  └── sources/raw_data/*.TAB + rabo_csv  → bank statements (ABN AMRO + Rabobank)

R pipeline
  ├── inkomsten.R            → income + hours processing → fin_wide, fin_long, bottom_line
  ├── bankStatements.R       → bank statement processing → maandelijkse_cat_long
  ├── duckdb_insert.R        → orchestrates both, writes to finhours.duckdb
  ├── data_validity.R        → pointblank validation, exports HTML reports
  └── modelinkomsten.R       → exploratory OLS + GAM models (not part of pipeline)

DuckDB: sources/financial_data/finhours.duckdb
  └── queried by Evidence.dev via sources/financial_data/*.sql (passthrough SELECT *)

Evidence.dev pages (pages/*.md)
  ├── index.md               → KPI overview (home)
  ├── salaris_uren.md        → salary components & trends
  ├── geboekte_uren.md       → hours breakdown & billable %
  ├── facturatie.md          → client billing (Entrador bottom line)
  ├── persoonlijke_rekening.md → personal account spending
  └── huisrekening.md        → household account spending
```

Run order: `duckdb_insert.R` (sources the others) → Evidence `npm run sources` → `npm run dev`.

---

## R Scripts

### inkomsten.R — Income & Hours Processing

**Inputs:** `financial.csv`, `legacy_financial.csv`, `*time_export*.csv`

**Payslip processing (`fin`):**
- Manual entries from NMBRS ESS app; one row per month.
- Derives computed columns: `bruto_variabel_inkomen`, `bruto_normaal_variabel_inkomen`, `bruto_vast_inkomen`, `variabel_inkomen_perc`, `urenbonus_inkomen_perc`, `tariefbonus_inkomen_perc`, `pensioen_perc`.
- `bruto_variabel_inkomen = urenbonus + tariefbonus + vakantiebijslagbonus + aanbrengbonus + plaatsingsbonus`
- `variabel_inkomen_perc = bruto_variabel_inkomen / salaris`

**Legacy payslip processing (`legacy_fin`):**
- Previous employer had different column names; mapped via `transmute()` to match current schema.
- Fields with no equivalent in the old schema are set to `NA_real_`.
- Both `fin` and `legacy_fin` are row-bound into `fin_wide` via `bind_rows()`.

**Hours processing (`billed_hours_cleaned`):**
- Multiple TimeChimp CSV exports merged with `map_df()`.
- Key date logic: `verloonde_datum = rollforward(datum, roll_to_first = T)` — hours worked in month X are paid in month X+1 (first day). This creates the `gewerkte_ym` / `verloonde_ym` distinction throughout the project.
- Hours converted from HH:MM:SS string to decimal: `as.numeric(hms(uren)) / 3600`.
- Project name cleaned via env var regex (`hours_project_regex`).
- `activiteit` assigned: `Inzet` if project starts with "Inzet", else inherits activiteit field.

**Key hour types (`name_filter` in fin_long):**
`Inzet`, `Educatie`, `Vakantieverlof`, `Intern overleg`, `Bijzonder verlof`, `Nationale feestdag`, `Ziek`, `Ouderschapsverlof (betaald)`, `Ouderschapsverlof (onbetaald)`, `Dokter/Tandarts`, `Urenbonus`, `Tariefbonus`, `Bonus totaal`, `No filter`

**Billable hours aggregation (`billed_hours`):**
- Vacation hours excluded before computing billable %.
- `facturabel_perc_gewerkte_ym = facturabel / (facturabel + niet_facturabel)`

**`fin_wide` construction:**
- `bind_rows(fin, legacy_fin)` → left join `billed_hours` on `ym = verloonde_ym` → left join `monthly_project_hours` on same key.
- NA from joins replaced with 0 (hours that did not occur are 0, not missing).
- Column deduplication: `gewerkte_ym.x` kept, `gewerkte_ym.y` dropped.

**`fin_long` construction:**
- `pivot_longer()` from column 7 onward.
- Adds `name_filter` column — a controlled vocabulary for filtering in the dashboard (only named hour types and bonus percentages get a label; everything else is `"No filter"`).

**`bottom_line` table:**
- Only rows with `status == "Gefactureerd"` (invoiced).
- Hardcoded hourly rates per end client (`uurtarief`): KLM=85, RVIG=95, RVIG verl=100, DT&V=100.
- `factuurbedrag = uren * uurtarief`.

---

### bankStatements.R — Bank Statement Processing

**Two bank accounts:**
- **ABN AMRO** (`rekening = "Chris"`): personal account. Raw format is TAB-delimited, no header, 8 columns. Counterparty and transaction type extracted from free-text `omschrijving` field via regex.
- **Rabobank** (`rekening = "Huis"`): household account. CSV with headers; transaction type already in a `code` column.

**ABN `rapportdatum` logic (critical):**
- Salary (detected via `str_detect(omschrijving, "salaris")`) anchors the reporting month.
- `rapportdatum` is set to `floor_date(transactiedatum, "month")` on salary rows, then `fill(.direction = "down")` propagates it forward.
- Transactions before the first salary entry are dropped (`filter(!is.na(rapportdatum))`).
- This means all ABN transactions are attributed to the salary month they fall under.

**Rabo `rapportdatum` logic:**
- Day of month >= 21 → allocate to next month (mimics the mid-month salary cycle cutoff).
- `rapportdatum = if_else(day(transactiedatum) >= 21, floor_date(datum %m+% months(1), "month"), floor_date(datum, "month"))`

**Categorization:**
- All category regex patterns stored in env vars (`Sys.getenv("abn_boodschappen")` etc.) — never hardcoded.
- ABN categories: `Boodschappen`, `Zorgkosten`, `Creditcard`, `Huisrekening`, `Intern`, `Filantropie`, `Abonnement`, `Werk`, `Overig`.
- Rabo categories: `Boodschappen`, `Afhalen & dineren`, `Kleding`, `Vaste kosten`, `Huisonderhoud`, `Contributie`, `Belastingen`, `Chris`, `Cel`, `Kinderbijslag`, `Overig`.
- `Chris` and `Cel` are named individuals who transfer to the household account.

**`maandelijkse_cat_long` aggregation:**
- Tax returns (`teruggave|teruggaaf`) filtered out before summing — they distort visualizations.
- Grouped by `rekening`, `rapportym`, `rapportdatum`, `categorie`, `richting` (Af/Bij).
- Result is the summed `transactiebedrag` per group.

---

### duckdb_insert.R — Pipeline Orchestrator

- Sources `inkomsten.R` and `bankStatements.R` to produce all data frames.
- Connects to `finhours.duckdb`.
- **Overwrite strategy**: `fin_wide`, `fin_long`, `bottom_line`, `maandelijkse_cat_long` are fully overwritten on each run (`overwrite = TRUE, append = FALSE`).
- **Append strategy**: `source_data_meta` and `wrangle_data_meta` append each run to build a history of updates.
- `source_data_meta`: file timestamps of all raw source files.
- `wrangle_data_meta`: row/column counts of `fin_long` and `fin_wide` at time of insert.
- After writing, calls `data_validity.R`.

---

### data_validity.R — Data Quality Validation

Uses `{pointblank}` to validate all four main tables after insert. Action threshold: warn if >1% of rows fail any check.

**Checks per table:**
- `fin_wide`: required columns exist, dates are dates, salaries > 0, `dagengewerkt` between 0–31, percentages between 0–1, no duplicate months.
- `fin_long`: no NULLs on key columns, `name_filter` within the known controlled vocabulary.
- `bottom_line`: hours > 0, rate > 0, `factuurbedrag == uren * uurtarief` (within 0.01 tolerance).
- `maandelijkse_cat_long`: no NULLs on all columns, `rekening` / `richting` / `categorie` within known sets, `rapportym` consistent with `rapportdatum`, no duplicate grouping key combinations.

HTML reports exported to `sources/financial_data/dq_*.html`.

---

### modelinkomsten.R — Exploratory Modeling (not in pipeline)

Two OLS models predicting `bruto_salaris`:
- Model 1: `bruto_salaris ~ facturabel_perc_gewerkte_ym`
- Model 2: adds `variabel_inkomen_perc + vakantieverlof`
- July and August 2024 excluded (known data entry errors in hours registration).

GAM model (`mgcv::gam`) on `netto_per_uur ~ s(uren)` to find the billable hours level that maximizes net income per hour. Uses a 200-point grid to locate the optimum.

---

## DuckDB Schema

**`fin_wide`** — One-Big-Table, monthly grain, payment month as key date.

| Column group | Columns |
|---|---|
| Time | `jaar`, `maand`, `ym`, `datum` (payment month), `gewerkte_ym`, `gewerkte_datum` (worked month) |
| Fixed income | `stamsalaris`, `salaris`, `netto_salaris`, `loonheffing` |
| Variable income | `urenbonus`, `tariefbonus`, `vakantiebijslag`, `vakantiebijslagbonus`, `aanbrengbonus`, `plaatsingsbonus`, `gratificatie` |
| Derived income | `bruto_variabel_inkomen`, `bruto_normaal_variabel_inkomen`, `bruto_vast_inkomen`, `variabel_inkomen_perc`, `urenbonus_inkomen_perc`, `tariefbonus_inkomen_perc` |
| Deductions | `pensioen`, `inhouding_pensioen`, `pensioen_perc`, `leaseauto`, `inhoudingen` |
| Benefits | `onkosten`, `mobiliteitsvergoeding`, `ouderschapsverlof` |
| Hours | `facturabel`, `niet_facturabel`, `facturabel_perc_gewerkte_ym`, `dagengewerkt` |
| Hour types | `inzet`, `educatie`, `vakantieverlof`, `intern_overleg`, `bijzonder_verlof`, `nationale_feestdag`, `ziek`, `betaald_ouderschapsverlof`, `onbetaald_ouderschapsverlof`, `dokter_tandarts`, `part_time` |

**`fin_long`** — Long format of `fin_wide` (columns 7+). Extra column `name_filter` for dashboard filtering.

**`bottom_line`** — Invoice-level table. Columns: `gewerkte_datum`, `gewerkte_ym`, `gewerkte_y`, `tussen_persoon` (intermediary), `eind_klant` (end client), `uren`, `uurtarief`, `factuurbedrag`.

**`maandelijkse_cat_long`** — Monthly bank transaction summary. Columns: `rekening` (Huis/Chris), `rapportym`, `rapportdatum`, `categorie`, `richting` (Af/Bij), `result`.

**`source_data_meta` / `wrangle_data_meta`** — Append-only audit tables.

---

## Evidence.dev Dashboard

SQL in pages is inline within Markdown fenced code blocks tagged with a query name. Queries can reference other queries as `${query_name}`. All SQL reads from `financial_data.*` (the DuckDB source alias).

**Common patterns:**
- Year filter via `<Dropdown>` + `${inputs.geselecteerd_jaar.value}` in `WHERE extract(year from ...) in ...`
- LAG window functions for month-over-month comparisons on KPI cards.
- `fin_long_year` and `fin_wide_year` as filtered base CTEs reused by downstream queries.
- `uurloon = netto_salaris / facturabel` (net income per billed hour).

**Salary page note:** Bruto total in SQL = `salaris + urenbonus + tariefbonus + vakantiebijslagbonus + vakantiebijslag + onkosten + mobiliteitsvergoeding + plaatsingsbonus + aanbrengbonus` — matches the manual `bruto_variabel_inkomen` definition in R.

**Vacation hours:** 144 hours/year is the hardcoded annual entitlement for the `vakantie_uren_over` calculation on the home page.

---

## Key Conventions

- **Dutch column names throughout** — do not rename to English.
- **Env vars for sensitive data** — category regex patterns and account numbers live in `.env`, never in code. Reference them with `Sys.getenv("var_name")`.
- **`gewerkte_*` vs `datum`/`ym`** — always distinguish the worked period from the payment period. Hours are worked in month N, paid in month N+1.
- **`rapportym` format** — `YYYYMM` string (e.g., `"202503"`), derived as `format(rapportdatum, "%Y%m")`.
- **Zero-fill after joins** — NA from left joins on hours data is replaced with 0, not left as NA.
- **Controlled vocabularies** — `rekening`, `richting`, `categorie`, `name_filter` all have fixed sets validated in `data_validity.R`. Add new values there when extending categories.
- **`{tidylog}`** — used selectively (`tidylog::filter`, `tidylog::mutate`) to log row counts during wrangling steps.
- **`{here}`** — all file paths use `here::here()`. Working directory is the project root.
