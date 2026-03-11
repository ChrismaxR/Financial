
# Flowchart
``` mermaid
flowchart LR
  subgraph RawData
    A[financial.csv]
    A2[*time_export*.csv]
    A3[statement_overview.csv]
  end

  subgraph EvidenceLogic
    K
    L
    M
    N
  end

  subgraph inkomen.R
    B
    C
    D
    E
    F
    G
  end

  subgraph duckDB
    I
  end


  A[financial.csv] --import--> B[fin_data -> fin]
  A2[*time_export*.csv] --import--> C[billed_hours_cleaned]
  A3[statement_overview.csv] --import--> D[legacy_fin]
  B --> E[join naar fin_wide]
  C --> E
  D --> E
  E --> F[fin_long]
  C --> G[bottom_line]
  F --> H[R/duckdb_insert.R]
  E --> H
  G --> H
  H --> I[(finhours.duckdb)]
  I --> J[fin_long.sql / fin_wide.sql / bottom_line.sql]
  J --> K[index.md]
  J --> L[financial.md]
  J --> M[booked_hours.md]
  J --> N[entrador.md]
  I --> O[source_data_meta + wrangle_data_meta]
  O --> K
```
---
