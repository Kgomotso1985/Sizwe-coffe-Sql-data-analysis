# Sizwe Coffee FY2025 SQL Analysis

## Project overview
This project looks at the Sizwe Coffee data for the FY2025 year-end review. Sizwe Coffee is a coffee roastery based in Johannesburg with a warehouse in Cape Town. They supply about 1,400 business outlets. They use two main channels: Wholesale (70% of revenue) and Subscription (30%). 

The purpose of this analysis is to answer eight business questions for the Financial Director and the National Sales Manager. The questions cover things like channel performance, profitability, collections, and why the profit margin dropped from 34.7% to 33.0%.

## Dataset
Tables used: `customers`, `products`, `sales_orders`, `sales_lines`, `ar_ledger`, `reps`, and `trade_promotions`.

Important notes on the data:
- I joined the tables using standard IDs like `customer_id`, `order_id`, and `sku`.
- Revenue was calculated using `sales_lines.line_revenue` because a sales order itself doesn't contain the value.

## Skills demonstrated
- Joining multiple tables together to get a full picture.
- Using `CASE WHEN` to group data into the two different fiscal years.
- Using `LEFT JOIN` so we don't lose track of customers who haven't been assigned a rep.
- Using `NOT EXISTS` to find wholesale customers without trade promotions.
- Using CTEs and Window Functions (`LAG`, `AVG OVER`) to see how sales change month by month.
- Calculating date differences in Databricks using `datediff`.

## How to run
This project was done in **Databricks SQL**.

1. First, I uploaded the nine CSV files to a Unity Catalog Volume at `/Volumes/workspace/default/sizwe_data/`.
2. I ran the `CREATE TABLE ... AS SELECT * FROM read_files(...)` statements to build the tables.
3. I used `DESCRIBE` to check the columns (and noted that the cost column in the sales lines table is called `cogs`).
4. I ran the queries in `queries.sql` to get the answers.

## Key insights
- **Channels:** Wholesale still brings in the most money (R335.4 million) and grew by 8.85%. Subscription grew at almost the same rate (8.84%).
- **Profit:** House Blend made the most gross profit (R10.7 million). Single Origin had the best margin (44.27%). Bulk Commercial has a very low margin (19.9%).
- **Collections:** Wholesale has a huge amount of unpaid invoices (R878.4 million) and they usually pay 17 days late. Subscription is paid on time, usually early.
- **Top Accounts:** Halvane Retail Group was the biggest customer at R3.8 million.
- **Promotions:** Umhlanga Fresh 108 is the biggest wholesale customer (R6.2 million) that doesn't have a promotion.
- **Reps:** Kagiso Mkhize brought in the most revenue (R59.9 million).
- **Seasonality:** Sales always drop in December but bounce back strongly in the new year. 
- **Margin Drop:** The margin dropped because Bulk Commercial (the lowest margin product) grew massively, while higher-margin coffees sold less.