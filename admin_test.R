setwd("C:/Users/anann/.gemini/antigravity-ide/scratch/college-feedback-sentiment-tool-R")
source("helpers/db.R")
source("helpers/nlp.R")

cat("=== ADMIN PORTAL FUNCTION TEST ===\n\n")

# 1. Authentication
u <- authenticate_user("admin@college.edu", "admin123")
cat("1. LOGIN:", if(!is.null(u)) paste("OK - Role:", u$role, "| Name:", u$name) else "FAILED", "\n")

# 2. Full dataset
df <- get_all_feedback()
cat("2. ALL FEEDBACK:", nrow(df), "rows,", ncol(df), "columns\n")

# 3. Aspect summary (drives bar charts)
sm <- get_aspect_summary()
cat("3. ASPECT SUMMARY:\n")
print(sm)

# 4. Facilities monitor
for (asp in c("labwork","library_facilities","extracurricular")) {
  sub <- df[df$aspect == asp, ]
  pos_pct <- if (nrow(sub) > 0) round(sum(sub$rating == 1) / nrow(sub) * 100, 1) else 0
  cat("4. FACILITY", asp, "-", pos_pct, "% positive\n")
}

# 5. Alert system
check_and_insert_alerts(0.30)
alerts <- get_alerts()
cat("5. ALERTS TRIGGERED:", nrow(alerts), "\n")
if (nrow(alerts) > 0) print(alerts[, c("entity_name", "avg_neg_score", "threshold")])

# 6. Net score computation
cat("6. NET SCORES:\n")
for (i in seq_len(nrow(sm))) {
  net <- round(((sm$positive[i] - sm$negative[i]) / max(sm$total[i], 1)) * 100, 1)
  cat("   ", sm$aspect[i], ":", net, "\n")
}

# 7. Word frequencies (for faculty word clouds)
pos_texts <- df[!is.na(df$text) & df$rating == 1, "text"]
freq <- get_word_frequencies(pos_texts, top_n = 5)
cat("7. TOP POSITIVE WORDS:\n")
print(freq)

cat("\n=== ALL ADMIN FUNCTIONS PASSED ===\n")
