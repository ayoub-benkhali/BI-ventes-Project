DROP TABLE IF EXISTS tmp_orders_raw;

CREATE TEMP TABLE tmp_orders_raw (
    col1 TEXT, col2 TEXT, col3 TEXT, col4 TEXT, col5 TEXT
);

COPY tmp_orders_raw FROM 'C:/chemin/vers/orders.csv'-- Remplacez par le chemin réel de votre fichier CSV
DELIMITER ',' CSV HEADER;



INSERT INTO DIM_DATE (full_date, day_of_month, day_of_week, day_name,
                      week_of_year, month_number, month_name, quarter, year, is_weekend)
SELECT
    d::DATE,
    EXTRACT(DAY     FROM d)::INTEGER,
    EXTRACT(ISODOW  FROM d)::INTEGER,
    TRIM(TO_CHAR(d, 'Day')),
    EXTRACT(WEEK    FROM d)::INTEGER,
    EXTRACT(MONTH   FROM d)::INTEGER,
    TRIM(TO_CHAR(d, 'Month')),
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(YEAR    FROM d)::INTEGER,
    EXTRACT(ISODOW  FROM d) IN (6, 7)
FROM generate_series(
    (SELECT MIN(col4::DATE) FROM tmp_orders_raw),
    (SELECT MAX(col4::DATE) FROM tmp_orders_raw),
    '1 day'::INTERVAL
) AS gs(d);