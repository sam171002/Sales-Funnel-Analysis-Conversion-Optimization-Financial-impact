-- 1. Count of orders by order status
SELECT 
    order_status,      
    COUNT(*) AS order_count  
FROM olist_orders
GROUP BY order_status  
ORDER BY order_count DESC;  

/* ---------------------------------------------------------------------------------------- */

-- 2. Summary statistics for Marketing Qualified Leads (MQLs) and deals
SELECT
    COUNT(DISTINCT mql.mql_id) AS total_mqls,  
    COUNT(DISTINCT deals.seller_id) AS contact_initiated,  -- Count of unique sellers who initiated contact
    COUNT(DISTINCT CASE WHEN deals.won_date IS NOT NULL THEN deals.seller_id END) AS deals_closed  
FROM olist_marketing_qualified_leads AS mql
LEFT JOIN olist_closed_deals AS deals 
    ON mql.mql_id = deals.mql_id; 

/* ---------------------------------------------------------------------------------------- */

-- 3. Calculate conversion time (time from first contact to deal closed) for each MQL
SELECT
    mql.mql_id,  
    DATEDIFF(deal.won_date, mql.first_contact_date) AS conversion_time  
FROM olist_marketing_qualified_leads mql
JOIN olist_closed_deals deal 
    ON mql.mql_id = deal.mql_id;  

/* ---------------------------------------------------------------------------------------- */

-- 4. Aggregate analysis of MQLs, deals, and conversion rates
SELECT 
    COUNT(mql.mql_id) AS total_mqls,  
    COUNT(DISTINCT deal.mql_id) AS contact_initiated,  
    COUNT(DISTINCT deal.mql_id) AS deals_closed,  
    ROUND(COUNT(DISTINCT deal.mql_id) / COUNT(mql.mql_id) * 100, 2) AS mql_to_contact_initiated_rate,  
    ROUND(COUNT(DISTINCT deal.mql_id) / COUNT(DISTINCT deal.mql_id) * 100, 2) AS contact_initiated_to_deals_closed_rate,  
    ROUND(AVG(DATEDIFF(deal.won_date, mql.first_contact_date)), 2) AS avg_conversion_time  -- Average conversion time for MQLs
FROM olist_marketing_qualified_leads mql
LEFT JOIN olist_closed_deals deal 
    ON mql.mql_id = deal.mql_id;  

/* ---------------------------------------------------------------------------------------- */

-- 5. Create a view for the funnel stages (MQL, Contact Initiated, Deals Closed)
CREATE VIEW funnel_view AS
SELECT 
    mql.mql_id,  
    mql.first_contact_date,  
    deal.won_date, 
    CASE 
        WHEN deal.mql_id IS NOT NULL THEN 'Deals Closed'  
        WHEN mql.first_contact_date IS NOT NULL THEN 'Contact Initiated'  
        ELSE 'MQL' 
    END AS funnel_stage  
FROM olist_marketing_qualified_leads mql
LEFT JOIN olist_closed_deals deal 
    ON mql.mql_id = deal.mql_id;  

SELECT * FROM funnel_view;

/* ---------------------------------------------------------------------------------------- */

-- 6. Funnel performance analysis: MQLs, Contact Initiated, Deals Closed, and Conversion Rates
SELECT 
    COUNT(DISTINCT mql_id) AS total_mqls,  
    SUM(CASE WHEN funnel_stage = 'Contact Initiated' THEN 1 ELSE 0 END) AS contact_initiated, 
    SUM(CASE WHEN funnel_stage = 'Deals Closed' THEN 1 ELSE 0 END) AS deals_closed, 
    ROUND(100 * SUM(CASE WHEN funnel_stage = 'Contact Initiated' THEN 1 ELSE 0 END) / COUNT(DISTINCT mql_id), 2) AS mql_to_contact_initiated_rate,  
    ROUND(100 * SUM(CASE WHEN funnel_stage = 'Deals Closed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN funnel_stage = 'Contact Initiated' THEN 1 ELSE 0 END), 0), 2) AS contact_initiated_to_deals_closed_rate,  -- Contact Initiated to Deals Closed rate (percentage)
    ROUND(AVG(DATEDIFF(won_date, first_contact_date)), 2) AS avg_conversion_time  
FROM funnel_view;

/* ---------------------------------------------------------------------------------------- */

-- 7. Drop-off analysis by origin (MQLs that drop off before closing deals)
SELECT 
    mql.origin,  
    COUNT(mql.mql_id) AS total_mqls,  
    COUNT(deal.mql_id) AS deals_closed,  
    COUNT(mql.mql_id) - COUNT(deal.mql_id) AS drop_offs,  -- Drop-off rate (MQLs without deals)
    ROUND((COUNT(deal.mql_id) / COUNT(mql.mql_id)) * 100, 2) AS conversion_rate  -- Conversion rate for each origin
FROM olist_marketing_qualified_leads AS mql
LEFT JOIN olist_closed_deals AS deal 
    ON mql.mql_id = deal.mql_id
GROUP BY mql.origin;  

/* ---------------------------------------------------------------------------------------- */

-- 8. Conversion rate analysis by origin and lead behavior profile
SELECT 
    mql.origin,  
    deal.lead_behaviour_profile,  
    COUNT(mql.mql_id) AS total_mqls,  
    COUNT(deal.mql_id) AS deals_closed,  
    ROUND((COUNT(deal.mql_id) / COUNT(mql.mql_id)) * 100, 2) AS conversion_rate  -- Conversion rate for each combination of origin and behavior profile
FROM olist_marketing_qualified_leads AS mql
LEFT JOIN olist_closed_deals AS deal 
    ON mql.mql_id = deal.mql_id
GROUP BY mql.origin, deal.lead_behaviour_profile;  

/* ---------------------------------------------------------------------------------------- */

-- 9. Summary table of average conversion times by origin and landing page
CREATE TABLE summary_conversion_times AS
SELECT 
    mql.origin,  
    mql.landing_page_id,  
    COUNT(mql.mql_id) AS total_mqls,  
    COUNT(deal.mql_id) AS deals_closed,  
    AVG(DATEDIFF(deal.won_date, mql.first_contact_date)) AS avg_conversion_time  
FROM olist_marketing_qualified_leads AS mql
LEFT JOIN olist_closed_deals AS deal 
    ON mql.mql_id = deal.mql_id
GROUP BY mql.origin, mql.landing_page_id;  
select*from summary_conversion_times