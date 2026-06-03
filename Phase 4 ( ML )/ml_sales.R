# ============================================================
# PHASE 4 - MACHINE LEARNING (FAST VERSION)
# ============================================================

library(RPostgres)
library(DBI)
library(dplyr)
library(ggplot2)
library(caret)
library(randomForest)
library(rpart)
library(gbm)
library(Metrics)

# ============================================================
# 1. CONNEXION POSTGRESQL
# ============================================================

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "dw_retail",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "ayoub"
)

cat("Connexion PostgreSQL OK\n")

# ============================================================
# 2. CHARGEMENT DONNÉES
# ============================================================

query <- "
SELECT 
    f.quantity,
    f.unit_price,
    f.cost_price,
    f.discount_amount,
    f.gross_amount,
    f.promotion_key,
    f.is_returned,
    d.month_number,
    d.quarter,
    d.year,
    d.is_weekend,
    s.city AS store_city,
    p.discount_band,
    p.discount_pct
FROM public.fact_sales f
LEFT JOIN public.dim_date d ON f.date_key = d.date_key
LEFT JOIN public.dim_store s ON f.store_key = s.store_key
LEFT JOIN public.dim_promotion p ON f.promotion_key = p.promotion_key
"

df <- dbGetQuery(con, query)
dbDisconnect(con)

cat("Données chargées:", nrow(df), "lignes\n")

# ============================================================
# 3. SAMPLING (IMPORTANT FOR SPEED)
# ============================================================

set.seed(42)
df <- df %>% sample_n(100000)

cat("Après sampling:", nrow(df), "lignes\n")

# ============================================================
# 4. CLEANING
# ============================================================

df$is_returned <- ifelse(df$is_returned == TRUE | df$is_returned == "TRUE", 1, 0)
df$is_weekend  <- as.integer(df$is_weekend)

df$discount_pct[is.na(df$discount_pct)] <- 0
df$discount_band[is.na(df$discount_band)] <- "Aucune"

df$discount_band <- as.factor(df$discount_band)
df$store_city    <- as.factor(df$store_city)

df <- na.omit(df)

# ============================================================
# 5. TRAIN / TEST SPLIT
# ============================================================

set.seed(42)
train_index <- createDataPartition(df$gross_amount, p = 0.8, list = FALSE)
train_data <- df[train_index, ]
test_data  <- df[-train_index, ]

cat("Train:", nrow(train_data), "| Test:", nrow(test_data), "\n")

# ============================================================
# 6. MODELS
# ============================================================

# Linear Regression
cat("Training Linear Regression...\n")
lm_model <- lm(gross_amount ~ ., data = train_data)
lm_pred <- predict(lm_model, test_data)

# Decision Tree
cat("Training Decision Tree...\n")
dt_model <- rpart(gross_amount ~ ., data = train_data)
dt_pred <- predict(dt_model, test_data)

# Random Forest (FAST)
cat("Training Random Forest...\n")
rf_model <- randomForest(gross_amount ~ ., data = train_data, ntree = 30)
rf_pred <- predict(rf_model, test_data)

# GBM (FAST)
cat("Training GBM...\n")
gbm_model <- gbm(
  gross_amount ~ .,
  data = train_data,
  n.trees = 30,
  interaction.depth = 2,
  shrinkage = 0.1,
  verbose = FALSE
)

gbm_pred <- predict(gbm_model, test_data, n.trees = 30)

# ============================================================
# 7. EVALUATION
# ============================================================

results <- data.frame(
  Model = c("Linear Regression", "Decision Tree", "Random Forest", "GBM"),
  MAE = c(
    mae(test_data$gross_amount, lm_pred),
    mae(test_data$gross_amount, dt_pred),
    mae(test_data$gross_amount, rf_pred),
    mae(test_data$gross_amount, gbm_pred)
  ),
  RMSE = c(
    rmse(test_data$gross_amount, lm_pred),
    rmse(test_data$gross_amount, dt_pred),
    rmse(test_data$gross_amount, rf_pred),
    rmse(test_data$gross_amount, gbm_pred)
  ),
  R2 = c(
    cor(test_data$gross_amount, lm_pred)^2,
    cor(test_data$gross_amount, dt_pred)^2,
    cor(test_data$gross_amount, rf_pred)^2,
    cor(test_data$gross_amount, gbm_pred)^2
  )
)

print(results[order(-results$R2), ])

# ============================================================
# 8. BEST MODEL
# ============================================================

best <- which.max(results$R2)
cat("\nBest Model:", results$Model[best], "\n")
cat("R2:", results$R2[best], "\n")
cat("MAE:", results$MAE[best], "\n")
cat("RMSE:", results$RMSE[best], "\n")