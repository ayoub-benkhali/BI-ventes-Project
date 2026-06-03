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
| Modélisation DW  | Schéma en étoile (Star Schema)|
| Machine Learning | Python (scikit-learn, pandas)|
| Reporting        | Dashboard (Phase 3)          |
| Versioning       | Git / GitHub                 |

---

## 🗃️ Modèle de données — Schéma en étoile

Le Data Warehouse `dw_retail` est structuré autour d'une **table de faits** et de plusieurs **tables de dimensions** :

```
         DIM_CLIENT
              │
DIM_PRODUIT ──┤
              │
         FACT_SALES ──── DIM_DATE
              │
DIM_MAGASIN ──┘
```

**Tables principales :**
- `FACT_SALES` — Mesures des ventes (quantité, chiffre d'affaires, marge, etc.)
- `DIM_DATE` — Dimension temporelle (jour, mois, trimestre, année)
- `DIM_PRODUIT` — Informations produits (catégorie, famille, prix)
- `DIM_CLIENT` — Informations clients (segment, région)
- `DIM_MAGASIN` — Informations points de vente (ville, région)

---

## 🚀 Installation & Clonage

### Prérequis

Assure-toi d'avoir installé les outils suivants :

- [Git](https://git-scm.com/) ≥ 2.x
- [PostgreSQL](https://www.postgresql.org/download/) ≥ 13
- [Talend Open Studio for Data Integration](https://www.talend.com/products/talend-open-studio/) (gratuit)
- [Python](https://www.python.org/) ≥ 3.8 (pour la phase ML)

---

### Étape 1 — Cloner le dépôt

```bash
git clone https://github.com/ayoub-benkhali/BI-ventes-Project.git
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

> 💡 **Remarque :** Remplace `postgres` par ton nom d'utilisateur PostgreSQL si différent.

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
1. Job_DIM_DATE
2. Job_DIM_PRODUIT
3. Job_DIM_CLIENT
4. Job_DIM_MAGASIN
5. Job_FACT_SALES
```

---

### Étape 5 — Vérifier le chargement

```sql
-- Vérification dans PostgreSQL
SELECT COUNT(*) FROM dim_date;
SELECT COUNT(*) FROM dim_produit;
SELECT COUNT(*) FROM fact_sales;
```

---

### Étape 6 — Phase ML (optionnel)

```bash
cd "Phase 4 ( ML )"
pip install -r requirements.txt
python main.py
```

---

## 👥 Auteurs

| Nom              | GitHub                                                        |
|------------------|---------------------------------------------------------------|
| Ayoub Benkhali   | [@ayoub-benkhali](https://github.com/ayoub-benkhali)         |

---

## 📄 Encadrement

Projet réalisé dans le cadre du cursus **L2 Business Intelligence** — ESEN Manouba  
Année universitaire **2025–2026**

---

## 📜 Licence

Ce projet est à des fins académiques uniquement.
