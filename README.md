# 🎓 Sentylitics (CampusListen)
### **An AI-Powered Institutional College Feedback & Sentiment Analytics Platform**

[![R Shiny](https://img.shields.io/badge/R_Shiny-v1.7+-276DC3.svg?style=flat&logo=R)](https://shiny.rstudio.com/)
[![Status](https://img.shields.io/badge/Status-Active_Development-success.svg)]()
[![Machine Learning](https://img.shields.io/badge/ML-SVM_%7C_Random_Forest_%7C_Logistic_Regression-orange.svg)]()

---

## 📌 Executive Summary

**Sentylitics (CampusListen)** is a unified, multi-portal web application engineered to transform qualitative and quantitative student feedback into real-time actionable sentiment intelligence. Traditional end-of-semester feedback forms yield static numerical averages that fail to capture specific student grievances or constructive learning suggestions. 

Built using **R Shiny**, **Natural Language Processing (NLP)**, and **Machine Learning (ML)** classifiers, Sentylitics bridges the gap between raw student feedback and academic governance by providing role-based portals for **Students**, **Faculty Members**, and **Institutional Administrators**.

---

## ✨ Key Features & Multi-Portal Architecture

### 🎓 **1. Student Portal (`modules/student_portal.R`)**
* **Multi-Aspect Rating Matrix:** Evaluates 6 core academic dimensions (*Teaching Pedagogy, Course Content & Syllabus, Examination & Assessment, Laboratory Work, Library Facilities, Extracurricular Support*).
* **Anonymity Preserving Toggle:** Allows students to submit reviews with zero-retaliation identity protection (`anonymous = 1`) while retaining academic metadata (Department & Semester).
* **Discrete Emotion Tagging:** Captures qualitative student sentiment paired with emotional states (*Satisfied, Neutral, Confused, Frustrated*).

### 👨‍🏫 **2. Faculty Portal (`modules/faculty_portal.R`)**
* **Interactive Sentiment Analytics:** Real-time pie and bar chart breakdowns of Positive (+1), Neutral (0), and Negative (-1) ratings powered by `plotly`.
* **Actionable Comment Extractor:** Algorithmic filter that extracts high-information constructive reviews while ignoring uninformative short text noise.
* **Instructional Action Tracker:** Enables faculty to log pedagogical remedies in response to student feedback.

### 🏛️ **3. Admin Executive Dashboard (`modules/admin_portal.R`)**
* **Institutional KPI Overview:** Macro-level monitoring of total feedback volume, positive sentiment percentage, active departments, and pending grievances.
* **Automated Early Warning Risk Alerts:** Automatically flags faculty members or departments where negative sentiment exceeds safety parameters ($\text{Negative Ratio} > 0.30$).
* **ML Model Center (`model_center.rds`):** Monitor pre-trained classifier benchmarks and initiate offline dataset retraining.

---

## 🔬 Machine Learning & NLP Pipeline

The platform incorporates an automated text processing pipeline (`helpers/nlp.R` & `model_trainer.R`) that tokenizes, normalizes, and classifies qualitative comments using 4 benchmark algorithms:

| Machine Learning Model | Classification Accuracy | Precision | F1-Score | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Linear Support Vector Machine (SVM)** | **76.47%** | **71.79%** | **72.79%** | 🏆 *Best Model* |
| **Random Forest Classifier** | **76.47%** | **72.58%** | **73.30%** | ✅ *Ensemble Model* |
| **Multinomial Logistic Regression** | **74.66%** | **70.37%** | **71.83%** | ✅ *Probabilistic* |
| **Naive Bayes Classifier** | **20.36%** | - | - | 📊 *Baseline* |

---

## 🛠️ Technology Stack

* **Frontend UI Framework:** R Shiny (`shiny`), `bslib` (Bootstrap 5 styling), `shinyjs`, Custom CSS (`Inter` typography, glassmorphism design system).
* **Data Analytics & Visualization:** `plotly`, `ggplot2`, `DT` (DataTables), `wordcloud2`.
* **Backend Runtime & DB:** R (v4.1.0+), RSQLite (`RSQLite`, `DBI`).
* **Machine Learning & NLP Stack:** `caret`, `e1071`, `randomForest`, `nnet`, `tm`, `tidytext`, `stringr`.

---

## 🚀 Quick Start Guide

### **Prerequisites**
* [R Language (v4.1.0 or higher)](https://cran.r-project.org/)
* RStudio (Optional, but recommended)

### **Step 1: Clone the Repository**
```bash
git clone https://github.com/anannyasunny79-maker/Sentylitics.git
cd Sentylitics
```

### **Step 2: Install Required R Packages**
Run the automated dependency setup script in R console or terminal:
```r
source("install_packages.R")
```

### **Step 3: Initialize Database & Demo Data**
```r
source("db_setup.R")
```

### **Step 4: Launch the Sentylitics Application**
```r
shiny::runApp()
# OR execute the launch helper:
source("run_app.R")
```

> **Windows Quick Launch:** Double-click [`Double_Click_To_Run.bat`](file:///c:/Users/anann/OneDrive/Sentylitics/Double_Click_To_Run.bat) to automatically install packages and launch the application.

---

## 🔑 Demo Account Credentials

| Role | Email Address | Password | Department |
| :--- | :--- | :--- | :--- |
| **Student** | `alex@college.edu` | `pass123` | Computer Science & Engineering |
| **Faculty** | `sunita@college.edu` | `pass123` | Electronics & Biomedical Engineering |
| **Admin** | `admin@college.edu` | `admin123` | Institutional Administration |

---

## 📁 Repository Structure

```
Sentylitics/
├── app.R                       # Main R Shiny application entry point & router
├── db_setup.R                  # Database initializer & demo seed script
├── model_trainer.R             # ML preprocessing & classifier trainer script
├── run_app.R                   # One-click execution script
├── Double_Click_To_Run.bat     # Windows batch launcher
├── data/
│   ├── sentilytics.db          # SQLite relational database store
│   └── model_center.rds        # Serialized Machine Learning model bundle
├── docs/                       # Project documentation & academic report files
│   ├── Sentylitics_Project_Report.md
│   └── Proposed_Solution_Project_Report.md
├── helpers/
│   ├── db.R                    # Database access layer & SQL queries
│   ├── nlp.R                   # Text normalization & cleaning engine
│   └── export.R                # CSV/PDF data exporter helper
├── modules/
│   ├── student_portal.R        # Student UI & submission logic
│   ├── faculty_portal.R        # Faculty analytics & action tracker UI
│   └── admin_portal.R          # Executive dashboard & ML model center UI
└── www/                        # Static web assets, logos & CSS design system
```

---

## 📄 Documentation & Academic Reports

Detailed technical documentation and project submission reports are available in the [`docs/`](docs/) directory:
* 📄 [**`Sentylitics Academic Project Report`**](docs/Sentylitics_Project_Report.md) — Complete 9-chapter academic report including SRS, Dataset details, Implementation, and Evaluation.
* 📄 [**`Proposed Solution Specification`**](docs/Proposed_Solution_Project_Report.md) — Architectural overview, mathematical formulations, and comparative analysis.

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
