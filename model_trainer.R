# model_trainer.R
# Preprocessing, training, and benchmarking of classifiers in R

library(readxl)
library(stringr)
library(jsonlite)

# Fallback English stopwords list
STOPWORDS <- c(
  "i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you", "your", "yours", 
  "yourself", "yourselves", "he", "him", "his", "himself", "she", "her", "hers", 
  "herself", "it", "its", "itself", "they", "them", "their", "theirs", "themselves", 
  "what", "which", "who", "whom", "this", "that", "these", "those", "am", "is", "are", 
  "was", "were", "be", "been", "being", "have", "has", "had", "having", "do", "does", 
  "did", "doing", "a", "an", "the", "and", "but", "if", "or", "because", "as", "until", 
  "while", "of", "at", "by", "for", "with", "about", "against", "between", "into", 
  "through", "during", "before", "after", "above", "below", "to", "from", "up", "down", 
  "in", "out", "on", "off", "over", "under", "again", "further", "then", "once", "here", 
  "there", "when", "where", "why", "how", "all", "any", "both", "each", "few", "more", 
  "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", 
  "than", "too", "very", "s", "t", "can", "will", "just", "don", "should", "now"
)

# Text cleaning function
clean_text <- function(text) {
  if (is.na(text) || !is.character(text)) return("")
  text <- tolower(text)
  text <- str_replace_all(text, "<[^>]+>", "") # Remove HTML
  text <- str_replace_all(text, "[^a-zA-Z0-9\\s]", "") # Remove special chars
  words <- unlist(strsplit(text, "\\s+"))
  words <- words[words != ""]
  words <- words[!(words %in% STOPWORDS)]
  cleaned <- paste(words, collapse = " ")
  return(cleaned)
}

# 1. Load and Melt College Feedback Excel
load_and_melt_college_data <- function(filepath) {
  df <- read_excel(filepath)
  
  aspects <- c("teaching", "coursecontent", "examination", "labwork", "library_facilities", "extracurricular")
  rating_cols <- c("teaching...1", "coursecontent...3", "examination", "labwork...7", "library_facilities...9", "extracurricular...11")
  text_cols <- c("teaching...2", "coursecontent...4", "Examination", "labwork...8", "library_facilities...10", "extracurricular...12")
  
  records <- list()
  record_idx <- 1
  
  for (i in 1:length(aspects)) {
    asp <- aspects[i]
    rat_col <- rating_cols[i]
    txt_col <- text_cols[i]
    
    for (row_idx in 1:nrow(df)) {
      rating <- df[[rat_col]][row_idx]
      text <- df[[txt_col]][row_idx]
      
      # Skip if both are NA or empty
      if (is.null(rating) || is.null(text)) next
      if (length(rating) == 0 || length(text) == 0) next
      if (is.na(rating) && (is.na(text) || str_trim(as.character(text)) == "")) next
      
      # Default rating to 0 (Neutral) if rating is missing but text exists
      if (is.na(rating)) rating <- 0
      
      text_str <- str_trim(as.character(text))
      if (text_str == "" || tolower(text_str) %in% c("nan", "null", "nil", "none")) next
      
      records[[record_idx]] <- list(
        aspect = asp,
        rating = as.integer(rating),
        raw_text = text_str,
        cleaned_text = clean_text(text_str)
      )
      record_idx <- record_idx + 1
    }
  }
  
  melted_df <- do.call(rbind, lapply(records, as.data.frame))
  return(melted_df)
}

train_and_save_all <- function(college_path, kaggle_path, save_dir) {
  message("Loading datasets in R...")
  college_df <- load_and_melt_college_data(college_path)
  kaggle_df <- read.csv(kaggle_path, stringsAsFactors = FALSE)
  kaggle_df$cleaned_text <- sapply(kaggle_df$feedback_text, clean_text)
  
  message("College melted dataset rows: ", nrow(college_df))
  message("Kaggle dataset rows: ", nrow(kaggle_df))
  
  # Load text processing libraries
  library(tm)
  library(caret)
  library(e1071)
  library(kernlab)
  library(randomForest)
  library(nnet) # For multinom logistic regression
  
  # Ensure target directory exists
  dir.create(save_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Write melted college data CSV
  write.csv(college_df, file.path(save_dir, "melted_college_data.csv"), row.names = FALSE)
  
  # --- Train Aspect Classifier ---
  message("Training Aspect Classifier in R...")
  # Create Corpus
  corpus_aspect <- Corpus(VectorSource(college_df$cleaned_text))
  dtm_aspect <- DocumentTermMatrix(corpus_aspect, control = list(weighting = weightTfIdf))
  dtm_aspect_m <- as.matrix(removeSparseTerms(dtm_aspect, 0.99))
  
  # Train Aspect classification model (SVM)
  aspect_train_data <- as.data.frame(dtm_aspect_m)
  aspect_train_data$y_aspect <- as.factor(college_df$aspect)
  
  aspect_model <- svm(y_aspect ~ ., data = aspect_train_data, kernel = "linear", probability = TRUE)
  # Save the vocabulary (features used during training)
  aspect_features <- colnames(dtm_aspect_m)
  
  # --- Train Sentiment Classifier Comparison ---
  message("Comparing Sentiment Classifiers (Naive Bayes, SVM, Logistic Regression, Random Forest)...")
  
  # Filter out rows with empty cleaned text
  sentiment_df <- college_df[college_df$cleaned_text != "", ]
  corpus_sent <- Corpus(VectorSource(sentiment_df$cleaned_text))
  dtm_sent <- DocumentTermMatrix(corpus_sent, control = list(weighting = weightTfIdf))
  dtm_sent_m <- as.matrix(removeSparseTerms(dtm_sent, 0.99))
  
  sent_features <- colnames(dtm_sent_m)
  sent_data <- as.data.frame(dtm_sent_m)
  sent_data$y_rating <- as.factor(sentiment_df$rating)
  
  # 80/20 train-test split
  set.seed(42)
  train_idx <- createDataPartition(sent_data$y_rating, p = 0.8, list = FALSE)
  train_set <- sent_data[train_idx, ]
  test_set <- sent_data[-train_idx, ]
  
  evaluation_results <- list()
  
  # 1. Naive Bayes
  message("Training Naive Bayes...")
  nb_model <- naiveBayes(y_rating ~ ., data = train_set)
  nb_pred <- predict(nb_model, test_set)
  
  # 2. SVM (Linear)
  message("Training SVM (Linear)...")
  svm_model <- svm(y_rating ~ ., data = train_set, kernel = "linear", probability = TRUE)
  svm_pred <- predict(svm_model, test_set)
  
  # 3. Logistic Regression (Multinomial)
  message("Training Logistic Regression...")
  lr_model <- multinom(y_rating ~ ., data = train_set, trace = FALSE)
  lr_pred <- predict(lr_model, test_set)
  
  # 4. Random Forest
  message("Training Random Forest...")
  rf_model <- randomForest(y_rating ~ ., data = train_set, ntree = 50)
  rf_pred <- predict(rf_model, test_set)
  
  # Function to compute metrics
  get_metrics <- function(pred, actual) {
    cm <- confusionMatrix(pred, actual)
    acc <- cm$overall["Accuracy"]
    
    # Calculate Precision, Recall, F1 (weighted)
    byClass <- cm$byClass
    # If 3 classes, byClass is a matrix.
    if (is.matrix(byClass)) {
      precisions <- byClass[, "Precision"]
      recalls <- byClass[, "Recall"]
      f1s <- byClass[, "F1"]
      
      # Handle NAs
      precisions[is.na(precisions)] <- 0
      recalls[is.na(recalls)] <- 0
      f1s[is.na(f1s)] <- 0
      
      # Weights based on class support
      weights <- table(actual) / length(actual)
      prec <- sum(precisions * weights)
      rec <- sum(recalls * weights)
      f1 <- sum(f1s * weights)
    } else {
      # 2 classes fallback
      prec <- ifelse(is.na(byClass["Precision"]), 0, byClass["Precision"])
      rec <- ifelse(is.na(byClass["Recall"]), 0, byClass["Recall"])
      f1 <- ifelse(is.na(byClass["F1"]), 0, byClass["F1"])
    }
    
    # Convert confusion matrix to 3x3 table array (-1, 0, 1)
    # Ensure levels are order matched: -1, 0, 1
    # Check levels in actual rating factor
    all_levels <- c("-1", "0", "1")
    full_cm <- matrix(0, nrow=3, ncol=3, dimnames=list(all_levels, all_levels))
    
    raw_table <- table(Actual = actual, Predicted = pred)
    for (act in rownames(raw_table)) {
      for (prd in colnames(raw_table)) {
        if (act %in% all_levels && prd %in% all_levels) {
          full_cm[act, prd] <- raw_table[act, prd]
        }
      }
    }
    
    return(list(
      accuracy = as.numeric(acc),
      precision = as.numeric(prec),
      recall = as.numeric(rec),
      f1_score = as.numeric(f1),
      confusion_matrix = as.matrix(full_cm)
    ))
  }
  
  evaluation_results[["Naive Bayes"]] <- get_metrics(nb_pred, test_set$y_rating)
  evaluation_results[["SVM (Linear)"]] <- get_metrics(svm_pred, test_set$y_rating)
  evaluation_results[["Logistic Regression"]] <- get_metrics(lr_pred, test_set$y_rating)
  evaluation_results[["Random Forest"]] <- get_metrics(rf_pred, test_set$y_rating)
  
  # --- Train Sarcasm and Emotion Classifiers ---
  message("Training Sarcasm and Emotion models in R...")
  # Process Kaggle corpus
  kaggle_corpus <- Corpus(VectorSource(kaggle_df$cleaned_text))
  kaggle_dtm <- DocumentTermMatrix(kaggle_corpus, control = list(weighting = weightTfIdf))
  kaggle_dtm_m <- as.matrix(removeSparseTerms(kaggle_dtm, 0.99))
  
  kaggle_features <- colnames(kaggle_dtm_m)
  
  # Sarcasm model (SVM)
  sarcasm_data <- as.data.frame(kaggle_dtm_m)
  sarcasm_data$y_sarcasm <- as.factor(kaggle_df$sarcasm_flag)
  sarcasm_model <- svm(y_sarcasm ~ ., data = sarcasm_data, kernel = "linear")
  
  # Emotion model (SVM)
  emotion_data <- as.data.frame(kaggle_dtm_m)
  emotion_data$y_emotion <- as.factor(kaggle_df$emotion_tag)
  emotion_model <- svm(y_emotion ~ ., data = emotion_data, kernel = "linear")
  
  # Save all models & feature lists into a single bundle
  model_bundle <- list(
    aspect_model = aspect_model,
    aspect_features = aspect_features,
    sentiment_model = lr_model, # Use Multinomial Logistic Regression as default production model
    sent_features = sent_features,
    sarcasm_model = sarcasm_model,
    emotion_model = emotion_model,
    kaggle_features = kaggle_features,
    evaluation_results = evaluation_results
  )
  
  saveRDS(model_bundle, file.path(save_dir, "model_center.rds"))
  write(toJSON(evaluation_results, auto_unbox = TRUE), file.path(save_dir, "benchmarks.json"))
  message("Model training completed successfully in R!")
}

# Run training
if (!interactive()) {
  train_and_save_all(
    "data/finalDataset0.2.xlsx",
    "data/student_feedback_dataset-selected-columns.csv",
    "data"
  )
}
