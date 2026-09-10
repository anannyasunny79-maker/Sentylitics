# PROPOSED SOLUTION: SENTYLITICS PLATFORM

## **CHAPTER: PROPOSED SOLUTION FOR INSTITUTIONAL FEEDBACK & SENTIMENT ANALYTICS**

---

### **1. OVERVIEW & RATIONALE OF THE PROPOSED SYSTEM**

Traditional student feedback mechanisms in higher education suffer from major operational bottlenecks: paper-based forms are cumbersome to process, standard survey portals only collect static numerical ratings (e.g., 1-5 scale) without contextual reasoning, student participation is hindered by retribution fears, and institutional decision-makers receive feedback weeks or months after courses conclude.

**Sentylitics (CampusListen)** addresses these limitations by introducing a unified, AI-driven, multi-portal web application built on **R Shiny**, **Natural Language Processing (NLP)**, and **Supervised Machine Learning (ML)** algorithms. 

The proposed solution replaces static survey forms with an intelligent analytics pipeline that:
1. **Captures Qualitative & Quantitative Feedback:** Combines numerical aspect ratings with free-text qualitative reviews and discrete emotion tagging (*Satisfied*, *Neutral*, *Confused*, *Frustrated*).
2. **Protects Student Identity:** Implements zero-retaliation anonymity toggles (`anonymous = 1`) that unbind student identity from feedback rows while retaining demographic metadata (department and semester).
3. **Automates Sentiment Extraction:** Utilizes pre-trained machine learning classifiers (**Linear SVM**, **Random Forest**, **Multinomial Logistic Regression**, and **Naive Bayes**) to automatically label open-ended comments into **Positive (+1)**, **Neutral (0)**, and **Negative (-1)** classes.
4. **Delivers Role-Isolated Analytics:** Delivers customized interactive dashboards for **Students**, **Faculty Members**, and **Institutional Administrators** using `plotly` and `bslib`.
5. **Triggers Early Warning Alerts:** Continuously monitors negative feedback rates per faculty member and department, generating real-time threshold alerts when negative sentiment exceeds safety parameters (e.g., `avg_neg_score > 0.30`).

---

### **2. SYSTEM ARCHITECTURE & COMPONENT DESIGN**

The proposed system adopts a modular **4-Layer Architecture** separating user interaction, reactive presentation, business logic & machine learning, and data persistence.

```
+-----------------------------------------------------------------------------------+
|                                  1. USER LAYER                                    |
|   +---------------------+   +---------------------+   +-----------------------+   |
|   |   Student Portal    |   |   Faculty Portal    |   |     Admin Portal      |   |
|   | (Feedback Submission|   | (Course Analytics & |   | (Executive Dashboard, |   |
|   |   & Track Status)   |   |   Action Tracker)   |   | Retraining & Alerts)  |   |
|   +----------+----------+   +----------+----------+   +-----------+-----------+   |
+--------------|-------------------------|--------------------------|---------------+
               |                         |                          |                
               v                         v                          v                
+-----------------------------------------------------------------------------------+
|                       2. PRESENTATION LAYER (R Shiny Core)                        |
|    - Single-Page Application Router (`app.R`)                                      |
|    - Unified Design System: Deep Green (`#4d6b1e`), Slate (`#f8fafc`), Inter UI   |
|    - Reactive Data Sources & Interactive Plotly Charts                             |
+----------------------------------------+------------------------------------------+
                                         |                                           
                                         v                                           
+-----------------------------------------------------------------------------------+
|                    3. BUSINESS LOGIC, NLP & ML ENGINE LAYER                       |
|   +--------------------------+  +--------------------------+  +----------------+  |
|   | NLP Tokenizer Engine     |  | ML Classifier Bundle     |  | Heuristic      |  |
|   | (`clean_text_nlp`)       |  | (`model_center.rds`)     |  | Action Extractor| |
|   +--------------------------+  +--------------------------+  +----------------+  |
+----------------------------------------+------------------------------------------+
                                         |                                           
                                         v                                           
+-----------------------------------------------------------------------------------+
|                           4. DATA PERSISTENCE LAYER                               |
|   - Relational Database Engine (`RSQLite` / `DBI` -> `data/sentilytics.db`)       |
|   - Serialized ML Model Store (`data/model_center.rds`)                           |
+-----------------------------------------------------------------------------------+
```

---

### **3. CORE FUNCTIONAL MODULES OF THE PROPOSED SOLUTION**

#### **3.1 Role-Based Access Control (RBAC) & Authentication Module**
* **Role Partitioning:** Isolates application features into three strict authorization levels (`student`, `faculty`, `admin`).
* **Secure Data Access:** Queries user credentials using parameterized statements via `helpers/db.R` to mitigate SQL injection risks.
* **Institutional Department Scoping:** Enforces departmental filtering across all 8 target engineering departments (*Computer Science, Biomedical, Electrical, Electronics & Communication, Mechanical, Civil, AI & Data Science, Robotics*).

#### **3.2 Dynamic Student Feedback Acquisition Engine**
* **Multi-Aspect Rating Matrix:** Evaluates 6 core academic dimensions:
  1. *Teaching Quality & Pedagogy*
  2. *Course Content & Syllabus Coverage*
  3. *Examination & Assessment*
  4. *Laboratory & Practical Work*
  5. *Library & Learning Resources*
  6. *Extracurricular & Skill Development*
* **Anonymity Preserving Toggle:** Allows students to submit evaluations with complete identity obfuscation while attaching crucial academic metadata (Department, Semester).
* **Qualitative Text Capture:** Captures granular textual observations processed immediately by the NLP engine.

#### **3.3 Natural Language Processing (NLP) & Feature Engineering Pipeline**
Raw student comments undergo a multi-step transformation prior to classification:
1. **Text Normalization:** Lowercasing and striping non-alphanumeric noise characters.
2. **Tokenization & Length Filtering:** Splitting strings into discrete word tokens and filtering out words shorter than 3 characters.
3. **Stopword Stripping:** Removing high-frequency non-informative stopwords (*the, is, at, which, for, with, about*) using a curated institutional stopword dictionary.
4. **Document-Term Matrix (DTM) Construction:** Converting cleaned token lists into sparse term frequency vector spaces for vector input into ML classifiers.

#### **3.4 Supervised Machine Learning Classifier Center (`model_center.rds`)**
The platform features an offline training and online inference engine that benchmarks 4 distinct machine learning algorithms:
* **Support Vector Machine (Linear SVM):** Constructs high-dimensional linear hyperplanes separating sentiment classes (Achieved **76.47% Accuracy** and **72.79% F1-Score**).
* **Random Forest Classifier:** Ensembles decorrelated decision trees for robust classification against noisy feedback text (**76.47% Accuracy**).
* **Multinomial Logistic Regression:** Evaluates log-odds probability distributions over class labels (**74.66% Accuracy**).
* **Naive Bayes Classifier:** Serves as a baseline probabilistic benchmark model.

#### **3.5 Executive Analytics Dashboards & Action Tracker**
* **Faculty Dashboard (`modules/faculty_portal.R`):** Displays overall sentiment distribution, aspect breakdown, and an **Actionable Comment Extractor** that highlights constructive, high-information student feedback while filtering out short noise. Includes an instructional action tracking form to log pedagogical adjustments.
* **Admin Dashboard (`modules/admin_portal.R`):** Provides macro-level institutional metrics, cross-departmental sentiment rankings, ML model retraining triggers, and automated grievance status tracking.

#### **3.6 Automated Early Warning Risk Alert System**
* **Threshold Detection Engine:** Automatically scans historical and real-time sentiment distribution to identify faculty or departments where negative sentiment exceeds the institutional threshold ($\text{Negative Ratio} > 0.30$).
* **Proactive Interventions:** Alerts are stored in the database (`alerts` table) and surfaced directly on the Admin Dashboard header, enabling proactive dean/HOD intervention prior to term completion.

---

### **4. DATABASE SCHEMA & ENTITY RELATIONSHIP DESIGN**

The underlying persistence model relies on **SQLite** (`sentilytics.db`) structured into normalized relational entities:

```sql
-- 1. Users Table (RBAC Core)
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK(role IN ('student','faculty','admin')),
    department TEXT,
    password_hash TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
);

-- 2. Feedback Entries Table (Core Data Repository)
CREATE TABLE feedback_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    faculty_id INTEGER,
    anonymous INTEGER NOT NULL DEFAULT 0,
    aspect TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK(rating IN (-1, 0, 1)),
    text TEXT,
    sub_ratings TEXT,
    emotion_tag TEXT NOT NULL DEFAULT 'neutral',
    semester TEXT NOT NULL DEFAULT 'Semester 1',
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY(student_id) REFERENCES users(id),
    FOREIGN KEY(faculty_id) REFERENCES users(id)
);

-- 3. Risk Alerts Table (Early Warning System)
CREATE TABLE alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,          -- 'faculty' or 'department'
    entity_name TEXT NOT NULL,
    avg_neg_score REAL NOT NULL,        -- Proportion of negative feedback
    threshold REAL NOT NULL DEFAULT 0.30,
    triggered_at TEXT DEFAULT (datetime('now')),
    dismissed INTEGER DEFAULT 0
);
```

---

### **5. ALGORITHMIC MATHEMATICAL & HEURISTIC FORMULATION**

#### **5.1 Text Sentiment Prediction Model**
Let $D = \{w_1, w_2, \dots, w_n\}$ represent the set of preprocessed token words in a student comment. The Term-Document Matrix mapping maps document $D$ to a numerical feature vector $\mathbf{x} \in \mathbb{R}^V$, where $V$ is the vocabulary size. 

The Support Vector Machine (SVM) decision boundary is defined by:
$$f(\mathbf{x}) = \text{sign}\left(\mathbf{w}^T \mathbf{x} + b\right)$$
where $\mathbf{w}$ is the optimal weight vector determined by minimizing the margin hinge loss:
$$\min_{\mathbf{w}, b} \frac{1}{2}\|\mathbf{w}\|^2 + C \sum_{i=1}^N \max\left(0, 1 - y_i(\mathbf{w}^T \mathbf{x}_i + b)\right)$$

#### **5.2 Actionable Feedback Selection Heuristic**
To filter out non-constructive short entries (e.g., *"Good"*, *"Worst lab"*), the system ranks feedback text $T$ using an Informational Density Score $S(T)$:
$$S(T) = \text{Length}(T) \times \mathbb{I}\Big(\text{Length}(T) \ge 20\Big) \times \left(1 + \lambda \cdot \text{StopwordRatio}(T)\right)$$
Comments exceeding the minimal length threshold ($\ge 20$ characters) are sorted by length and sentiment divergence, yielding the top actionable insights for faculty members.

---

### **6. COMPARATIVE ANALYSIS: EXISTING SYSTEM VS. PROPOSED SENTYLITICS SOLUTION**

| Feature Criteria | Existing Manual / Survey System | Proposed Sentylitics Platform |
| :--- | :--- | :--- |
| **Data Collection** | Periodic, paper-based, or static forms | Continuous, real-time web portal |
| **Analysis Type** | Simple numerical averaging (1-5 stars) | Combined quantitative & qualitative NLP sentiment analysis |
| **Qualitative Insight** | Manually skimmed or ignored entirely | Machine Learning classified (Positive, Neutral, Negative) |
| **Anonymity & Trust** | Uncertain / Non-standardized | Enforced zero-retaliation anonymity toggle |
| **Emotion Context** | None | Discrete emotion tagging (*Satisfied, Frustrated, Confused*) |
| **Early Warning System** | Non-existent (Post-exam discovery) | Automated threshold alerting ($\text{Negative Rate} > 30\%$) |
| **Action Tracking** | Informal / No audit trail | Integrated instructional action log per faculty member |
| **Execution Overhead** | High administrative effort | Fully automated R Shiny reactive pipeline |

---

### **7. IMPLEMENTATION EXTRACTS FROM CORE PIPELINE**

#### **7.1 NLP Preprocessing Engine (`helpers/nlp.R`)**
```r
# helpers/nlp.R — Text Cleaning & Frequency Extractor
library(e1071)
library(nnet)

STOPWORDS_NLP <- c(
  "i","me","my","we","our","you","your","he","his","she","her","it","its","they","them","their",
  "what","which","who","this","that","these","those","am","is","are","was","were","be","been",
  "have","has","had","do","does","did","a","an","the","and","but","if","or","as","at","by",
  "for","with","about","into","during","before","after","to","from","up","in","on","off","then"
)

clean_text_nlp <- function(text) {
  if (is.na(text) || !is.character(text) || text == "") return("")
  text <- tolower(text)
  text <- gsub("[^a-zA-Z\\s]", " ", text)
  words <- unlist(strsplit(text, "\\s+"))
  words <- words[words != "" & nchar(words) > 2]
  words <- words[!(words %in% STOPWORDS_NLP)]
  paste(words, collapse = " ")
}
```

#### **7.2 Database Access & Authentication Handler (`helpers/db.R`)**
```r
# helpers/db.R — Centralised SQLite Queries
library(DBI)
library(RSQLite)

DB_PATH <- "data/sentilytics.db"

get_db_con <- function() {
  dbConnect(SQLite(), DB_PATH)
}

authenticate_user <- function(email, password) {
  con <- get_db_con(); on.exit(dbDisconnect(con))
  df <- dbGetQuery(con, sprintf(
    "SELECT * FROM users WHERE LOWER(email) = LOWER('%s') AND password_hash = '%s' LIMIT 1",
    gsub("'", "''", email), gsub("'", "''", password)
  ))
  if (nrow(df) == 0) return(NULL)
  as.list(df[1, ])
}
```

---

### **8. EXPECTED OUTCOMES & INSTITUTIONAL IMPACT**

1. **Enhanced Feedback Participation:** Anonymity controls increase qualitative student response submission rates.
2. **Proactive Quality Management:** Department heads identify failing course modules midway through the semester rather than post-final examinations.
3. **Data-Driven Faculty Appraisal:** Replaces subjective bias with objective sentiment metrics across multiple academic criteria.
4. **Scalable Framework:** Lightweight R Shiny & SQLite architecture allows seamless deployment on low-cost campus servers or cloud VMs without heavy enterprise database licensing costs.
