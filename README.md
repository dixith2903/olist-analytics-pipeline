# 🛒 Olist Marketplace Analytics Pipeline

End-to-end analytics project on 100K+ real orders from a Brazilian e-commerce marketplace — from raw CSVs to a live Power BI dashboard.

**📊 Dashboard previews below — full .pbix file included in this repo**

## The Pipeline

Raw CSVs (9 tables)
   ▼ PYTHON — ETL: timestamps, nulls, category translation, delivery KPIs, geolocation aggregation (1M → 19K)
   ▼ SQL SERVER — Star schema (4 dims, 3 facts) + 26 queries: JOINs, CTEs, window functions
   ├── EXCEL — Seller scorecard: XLOOKUP, VLOOKUP, LOOKUP, HLOOKUP, INDEX/MATCH + pivot dashboard
   └── POWER BI — 4-page dashboard: Sales, Categories, Delivery Operations, Sellers & Reviews

## Key Insights

- 🔁 **3.1% repeat customer rate** — the marketplace ran on acquisition, not retention
- ⏰ **Late deliveries destroy reviews** — early = 4.29/5, 8+ days late = 1.71/5
- 📍 **São Paulo = 37% of revenue** (5.7M of 15.4M)
- 🚚 **On-time delivery reached 94%** by late 2018, up from much worse in 2016-17

## Screenshots

![Overview](screenshot/Executive%20Overview.png)
![Delivery](screenshot/Logistics%20&%20Delivery.png)

## Tools

Python (pandas) • SQL Server (SSMS) • Power BI (DAX) • Excel

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
