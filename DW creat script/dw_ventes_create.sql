-- ============================================================
--  DATA WAREHOUSE - ANALYSE DES VENTES
--  Base de données : PostgreSQL
--  Schéma : star schema (schéma en étoile)
--  Auteur  : généré via Claude / Anthropic
-- ============================================================

-- ============================================================
--  SUPPRESSION DES TABLES (ordre respectant les FK)
-- ============================================================
DROP TABLE IF EXISTS fact_sales       CASCADE;
DROP TABLE IF EXISTS dim_date         CASCADE;
DROP TABLE IF EXISTS dim_customer     CASCADE;
DROP TABLE IF EXISTS dim_product      CASCADE;
DROP TABLE IF EXISTS dim_store        CASCADE;
DROP TABLE IF EXISTS dim_promotion    CASCADE;
DROP TABLE IF EXISTS dim_shipment     CASCADE;


-- ============================================================
--  1. DIM_DATE
--  Construite synthétiquement à partir des dates de commandes.
--  Permet toutes les analyses temporelles (jour, mois, trimestre, an).
-- ============================================================
CREATE TABLE dim_date (
    date_key        SERIAL        PRIMARY KEY,          -- PK surrogate
    full_date       DATE          NOT NULL UNIQUE,       -- 2021-08-26
    day_of_month    SMALLINT      NOT NULL,              -- 1-31
    day_of_week     SMALLINT      NOT NULL,              -- 1=Lundi .. 7=Dimanche
    day_name        VARCHAR(10)   NOT NULL,              -- 'Monday'
    week_of_year    SMALLINT      NOT NULL,              -- 1-53
    month_number    SMALLINT      NOT NULL,              -- 1-12
    month_name      VARCHAR(10)   NOT NULL,              -- 'August'
    quarter         SMALLINT      NOT NULL,              -- 1-4
    year            SMALLINT      NOT NULL,              -- 2021
    is_weekend      BOOLEAN       NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE dim_date IS
  'Dimension temps. Grain : un enregistrement par jour calendaire couvert par les commandes.';



-- ============================================================
--  2. DIM_CUSTOMER
--  Source : customers.csv
--  Permet de segmenter les ventes par localisation et ancienneté.
-- ============================================================
CREATE TABLE dim_customer (
    customer_key        SERIAL        PRIMARY KEY,      -- PK surrogate
    customer_id         INTEGER       NOT NULL UNIQUE,  -- NK source
    city                VARCHAR(100),
    signup_date         DATE,
    customer_segment    VARCHAR(30),                    -- calculé ETL : 'New','Regular','Loyal'
    signup_year         SMALLINT                        -- extrait de signup_date
);

COMMENT ON TABLE dim_customer IS
  'Dimension client. Grain : un enregistrement par client unique.';


-- ============================================================
--  3. DIM_PRODUCT
--  Sources : products.csv + categories.csv + suppliers.csv
--  Hiérarchie : Produit → Catégorie  |  Produit → Fournisseur
-- ============================================================
CREATE TABLE dim_product (
    product_key         SERIAL        PRIMARY KEY,      -- PK surrogate
    product_id          INTEGER       NOT NULL UNIQUE,  -- NK source
    category_id         INTEGER,
    category_name       VARCHAR(50),
    supplier_id         INTEGER,
    supplier_country    VARCHAR(60),
    cost_price          NUMERIC(12,2) NOT NULL           -- prix catalogue source
);

COMMENT ON TABLE dim_product IS
  'Dimension produit enrichie via jointure categories + suppliers.';


-- ============================================================
--  4. DIM_STORE
--  Sources : stores.csv + agrégat employees.csv
--  Permet de comparer la performance des magasins.
-- ============================================================
CREATE TABLE dim_store (
    store_key           SERIAL        PRIMARY KEY,      -- PK surrogate
    store_id            INTEGER       NOT NULL UNIQUE,  -- NK source
    city                VARCHAR(100),
    nb_employees        INTEGER,                        -- calculé ETL : COUNT(employee_id)
    avg_salary          NUMERIC(10,2)                   -- calculé ETL : AVG(salary)
);

COMMENT ON TABLE dim_store IS
  'Dimension magasin. Métriques employés précalculées lors du chargement ETL.';


-- ============================================================
--  5. DIM_PROMOTION
--  Source : promotions.csv
--  Permet de mesurer l'impact des remises sur les ventes.
-- ============================================================
CREATE TABLE dim_promotion (
    promotion_key       SERIAL        PRIMARY KEY,      -- PK surrogate
    promotion_id        INTEGER       NOT NULL UNIQUE,  -- NK source
    discount_pct        NUMERIC(5,2)  NOT NULL,         -- taux de remise en %
    discount_band       VARCHAR(20)                     -- 'Faible','Moyen','Fort' (ETL)
);

-- Ligne "aucune promotion" pour les commandes sans promo
INSERT INTO dim_promotion (promotion_id, discount_pct, discount_band)
VALUES (0, 0.00, 'Aucune');

COMMENT ON TABLE dim_promotion IS
  'Dimension promotion. Inclut une ligne sentinelle (id=0) pour les ventes sans remise.';


-- ============================================================
--  6. DIM_SHIPMENT
--  Source : shipments.csv
--  Permet l'analyse logistique et son corrélation avec les retours.
-- ============================================================
CREATE TABLE dim_shipment (
    shipment_key        SERIAL        PRIMARY KEY,      -- PK surrogate
    shipment_id         INTEGER       NOT NULL UNIQUE,  -- NK source
    order_id            INTEGER       NOT NULL,         -- jointure avec orders
    status              VARCHAR(20)   NOT NULL           -- 'delivered','shipped','late'
);

COMMENT ON TABLE dim_shipment IS
  'Dimension livraison. Grain : une livraison par commande.';


-- ============================================================
--  7. FACT_SALES
--  Grain : une ligne = un article commandé (order_item)
--  Toutes les mesures analytiques sont précalculées pour la performance.
-- ============================================================
CREATE TABLE fact_sales (
    -- Clé primaire de la table de faits
    fact_id             BIGSERIAL     PRIMARY KEY,

    -- Clés naturelles conservées pour audit/traçabilité
    order_item_id       INTEGER       NOT NULL,
    order_id            INTEGER       NOT NULL,

    -- Clés étrangères vers les dimensions
    date_key            INTEGER       NOT NULL REFERENCES dim_date(date_key),
    customer_key        INTEGER       NOT NULL REFERENCES dim_customer(customer_key),
    product_key         INTEGER       NOT NULL REFERENCES dim_product(product_key),
    store_key           INTEGER       NOT NULL REFERENCES dim_store(store_key),
    promotion_key       INTEGER       NOT NULL REFERENCES dim_promotion(promotion_key),
    shipment_key        INTEGER               REFERENCES dim_shipment(shipment_key),

    -- ---- MESURES -----------------------------------------------
    quantity            INTEGER       NOT NULL DEFAULT 0,          -- order_items.qty
    unit_price          NUMERIC(12,2) NOT NULL DEFAULT 0.00,       -- order_items.price
    cost_price          NUMERIC(12,2) NOT NULL DEFAULT 0.00,       -- products.price (snapshot)

    gross_amount        NUMERIC(14,2) NOT NULL DEFAULT 0.00,       -- qty × unit_price
    discount_amount     NUMERIC(14,2) NOT NULL DEFAULT 0.00,       -- gross × discount_pct/100
    net_amount          NUMERIC(14,2) NOT NULL DEFAULT 0.00,       -- gross - discount
    payment_amount      NUMERIC(14,2)          DEFAULT 0.00,       -- payments.amount (réparti)

    profit              NUMERIC(14,2) NOT NULL DEFAULT 0.00,       -- net - cost_price×qty

    is_returned         BOOLEAN       NOT NULL DEFAULT FALSE,      -- présent dans returns.csv
    refund_amount       NUMERIC(14,2)          DEFAULT 0.00        -- returns.refund (si retour)
);

COMMENT ON TABLE fact_sales IS
  'Table de faits principale. Grain : une ligne par article commandé (order_item).';

-- ============================================================
--  INDEX POUR LES REQUÊTES ANALYTIQUES FRÉQUENTES
-- ============================================================
CREATE INDEX idx_fs_date        ON fact_sales(date_key);
CREATE INDEX idx_fs_customer    ON fact_sales(customer_key);
CREATE INDEX idx_fs_product     ON fact_sales(product_key);
CREATE INDEX idx_fs_store       ON fact_sales(store_key);
CREATE INDEX idx_fs_promotion   ON fact_sales(promotion_key);
CREATE INDEX idx_fs_shipment    ON fact_sales(shipment_key);
CREATE INDEX idx_fs_order       ON fact_sales(order_id);
CREATE INDEX idx_fs_returned    ON fact_sales(is_returned) WHERE is_returned = TRUE;


-- ============================================================
--  VUES ANALYTIQUES (KPI pré-calculés)
-- ============================================================

-- KPI global par mois
CREATE OR REPLACE VIEW v_kpi_monthly AS
SELECT
    d.year,
    d.month_number,
    d.month_name,
    COUNT(DISTINCT f.order_id)                                  AS nb_orders,
    SUM(f.quantity)                                             AS total_qty,
    ROUND(SUM(f.gross_amount), 2)                               AS ca_brut,
    ROUND(SUM(f.net_amount),   2)                               AS ca_net,
    ROUND(SUM(f.profit),       2)                               AS profit_brut,
    ROUND(SUM(f.net_amount) / NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS panier_moyen,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.net_amount), 0) * 100, 2)        AS marge_pct,
    ROUND(SUM(CASE WHEN f.is_returned THEN 1 ELSE 0 END)::NUMERIC
          / NULLIF(COUNT(*), 0) * 100, 2)                       AS taux_retour_pct
FROM fact_sales f
JOIN dim_date    d ON f.date_key = d.date_key
GROUP BY d.year, d.month_number, d.month_name
ORDER BY d.year, d.month_number;

-- KPI par magasin
CREATE OR REPLACE VIEW v_kpi_by_store AS
SELECT
    s.store_id,
    s.city,
    s.nb_employees,
    ROUND(SUM(f.net_amount),  2)  AS ca_net,
    ROUND(SUM(f.profit),      2)  AS profit_brut,
    COUNT(DISTINCT f.order_id)    AS nb_orders,
    ROUND(SUM(f.net_amount) / NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS panier_moyen
FROM fact_sales f
JOIN dim_store s ON f.store_key = s.store_key
GROUP BY s.store_id, s.city, s.nb_employees
ORDER BY ca_net DESC;

-- Taux de livraison à temps
CREATE OR REPLACE VIEW v_delivery_performance AS
SELECT
    sh.status,
    COUNT(*)                                                    AS nb_livraisons,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2)  AS pct_total
FROM fact_sales f
JOIN dim_shipment sh ON f.shipment_key = sh.shipment_key
GROUP BY sh.status;

-- Impact promotions
CREATE OR REPLACE VIEW v_promotion_impact AS
SELECT
    p.promotion_id,
    p.discount_pct,
    p.discount_band,
    COUNT(DISTINCT f.order_id)     AS nb_orders,
    ROUND(SUM(f.gross_amount), 2)  AS ca_brut,
    ROUND(SUM(f.net_amount),   2)  AS ca_net,
    ROUND(SUM(f.discount_amount),2) AS total_remise
FROM fact_sales f
JOIN dim_promotion p ON f.promotion_key = p.promotion_key
GROUP BY p.promotion_id, p.discount_pct, p.discount_band
ORDER BY total_remise DESC;
