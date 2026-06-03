# 📊 Projet BI — Analyse des Ventes

> Projet de Business Intelligence réalisé dans le cadre de la Licence L2 BI — ESEN Manouba (2025–2026).  
> Ce projet couvre l'ensemble du pipeline décisionnel : modélisation d'un entrepôt de données, ETL avec Talend, tableau de bord analytique et Machine Learning.

---

## 🗂️ Structure du projet

```
BI-ventes-Project/
│
├── DW creat script/              # Scripts SQL de création du Data Warehouse (PostgreSQL)
│   └── ...                       # Schéma en étoile : tables de faits et dimensions
│
├── ETL phase ( talend )/         # Jobs Talend Open Studio (extraction, transformation, chargement)
│   └── ...                       # Alimentation des dimensions et de la table de faits
│
├── Phase 3 ( dashboard )/        # Tableaux de bord et visualisations analytiques
│   └── ...
│
├── Phase 4 ( ML )/               # Modèles de Machine Learning (prédiction / segmentation)
│   └── ...
│
└── Projet de Business Intelligence 2025-2026.pdf   # Énoncé du projet
```

---

## 🏗️ Architecture

Le projet suit une architecture décisionnelle classique en **4 phases** :

```
Source de données
      │
      ▼
 ┌─────────────────────────────────────┐
 │   Phase 1 — Data Warehouse (DW)     │
 │   Schéma en étoile · PostgreSQL     │
 └─────────────────────────────────────┘
      │
      ▼
 ┌─────────────────────────────────────┐
 │   Phase 2 — ETL (Talend)            │
 │   Extraction · Transformation ·     │
 │   Chargement des données            │
 └─────────────────────────────────────┘
      │
      ▼
 ┌─────────────────────────────────────┐
 │   Phase 3 — Dashboard               │
 │   Visualisation & Reporting         │
 └─────────────────────────────────────┘
      │
      ▼
 ┌─────────────────────────────────────┐
 │   Phase 4 — Machine Learning        │
 │   Prédiction & Analyse avancée      │
 └─────────────────────────────────────┘
```

---

## 🛠️ Technologies utilisées

| Composant        | Technologie                  |
|------------------|------------------------------|
| Base de données  | PostgreSQL                   |
| ETL              | Talend Open Studio           |
| Modélisation DW  | Schéma en étoile(Star Schema)|
| Machine Learning | R                            |
| Reporting        | Dashboard (Power bi)         |
| Versioning       | Git / GitHub                 |

---

## 🗃️ Modèle de données — Schéma en étoile

Le Data Warehouse `dw_retail` est structuré autour d'une **table de faits** et de **6 tables de dimensions** :

```
                        DIM_CUSTOMER
                             │
            DIM_PRODUCT ─────┤
                             │
DIM_DATE ────────────── FACT_SALES ───── DIM_PROMOTION
                             │
           DIM_STORE ────────┤
                             │
                        DIM_SHIPMENT
```

**Tables principales :**

- `FACT_SALES` 
- `DIM_DATE` 
- `DIM_CUSTOMER` 
- `DIM_PRODUCT` 
- `DIM_STORE` 
- `DIM_PROMOTION` 
- `DIM_SHIPMENT` 

**Clés étrangères de `FACT_SALES` :**

| Clé étrangère    | Table de dimension |
|------------------|--------------------|
| `date_key`       | `DIM_DATE`         |
| `customer_key`   | `DIM_CUSTOMER`     |
| `product_key`    | `DIM_PRODUCT`      |
| `store_key`      | `DIM_STORE`        |
| `promotion_key`  | `DIM_PROMOTION`    |
| `shipment_key`   | `DIM_SHIPMENT`     |

---

## 🚀 Installation & Clonage

### Prérequis

Assure-toi d'avoir installé les outils suivants :

- Git
- PostgreSQL
- Talend Open Studio for Data Integration
- Power bi
- Rstudio
---

### Étape 1 — Cloner le dépôt

```bash
git clone https://github.com/ayoub-benkhali/BI-ventes-Project
cd BI-ventes-Project
```

---

### Étape 2 — Créer la base de données PostgreSQL

Connecte-toi à PostgreSQL et crée la base de données :

```sql
-- Dans psql ou pgAdmin
CREATE DATABASE dw_retail;
```

Puis exécute le script de création du schéma :

```bash
psql -U postgres -d dw_retail -f "DW creat script/create_dw.sql"
```

Ensuite, exécute le script de remplissage de la dimension date :
 
```bash
psql -U postgres -d dw_retail -f "DW creat script/insert_dim_date.sql"
```
 
> 💡 **Remarque :** Remplace `postgres` par ton nom d'utilisateur PostgreSQL si différent.
 
> 🔴 **IMPORTANT :** Avant d'exécuter les jobs ETL, remplace le schéma du fichier `orders.csv` par ton schéma réel selon la structure de tes données sources.

---

### Étape 3 — Configurer la connexion dans Talend

1. Ouvre **Talend Open Studio**
2. Importe le projet depuis le dossier `ETL phase ( talend )/`
3. Dans la palette, configure ta connexion PostgreSQL :
   - **Host :** `localhost`
   - **Port :** `5432`
   - **Database :** `dw_retail`
   - **Username :** `postgres` *(ou ton utilisateur)*
   - **Password :** *(ton mot de passe)*

---

### Étape 4 — Exécuter les jobs ETL

Dans Talend, exécute les jobs dans l'ordre suivant :

```
1. Job_DIM_CUSTOMER
2. Job_DIM_PRODUCT
3. Job_DIM_PROMOTION
4. Job_DIM_SHIPMENT
5. Job_DIM_STORE
6. Job_FACT_SALES
```

> ⚠️ **Important :** Les dimensions doivent toujours être chargées **avant** la table de faits.

---

### Étape 5 — Vérifier le chargement

```sql
-- Vérification dans PostgreSQL
SELECT COUNT(*) FROM dim_customer;
SELECT COUNT(*) FROM dim_product;
SELECT COUNT(*) FROM dim_store;
SELECT COUNT(*) FROM dim_promotion;
SELECT COUNT(*) FROM dim_shipment;
SELECT COUNT(*) FROM fact_sales;
```

---

### Étape 6 — Phase ML (optionnel)

```bash
cd Phase 4 ( ML )
ml_sales.R
```

---

## 👥 Auteurs

| Nom              | GitHub                                 |
|------------------|----------------------------------------|
| Ayoub Ben Khali     | https://github.com/ayoub-benkhali        |

---
