# helpers/nlp.R
# NLP utility functions for extracting actionable comments and word frequencies

library(e1071)
library(nnet)

STOPWORDS_NLP <- c(
  "i","me","my","we","our","you","your","he","his","she","her","it","its","they","them","their",
  "what","which","who","this","that","these","those","am","is","are","was","were","be","been",
  "have","has","had","do","does","did","a","an","the","and","but","if","or","as","at","by",
  "for","with","about","into","during","before","after","to","from","up","in","on","off","then",
  "here","when","where","how","all","any","both","each","more","most","other","some","such",
  "no","not","only","so","than","too","very","can","will","just","now","also","get","got",
  "would","could","should","much","many","well","even","still","back","need","may","might","us"
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

# Extract word frequency table from a vector of texts
get_word_frequencies <- function(texts, top_n = 50) {
  all_words <- unlist(lapply(texts, function(t) {
    cleaned <- clean_text_nlp(t)
    unlist(strsplit(cleaned, "\\s+"))
  }))
  all_words <- all_words[all_words != ""]
  if (length(all_words) == 0) return(data.frame(word = character(), freq = integer()))
  freq_tbl <- sort(table(all_words), decreasing = TRUE)
  head(data.frame(word = names(freq_tbl), freq = as.integer(freq_tbl), stringsAsFactors = FALSE), top_n)
}

# Get actionable comments: long text, not sarcastic, informative
get_actionable_comments <- function(df, model_bundle = NULL, top_n = 5) {
  if (is.null(df) || nrow(df) == 0) return(character(0))

  # Filter to non-empty text with decent length (> 20 chars)
  df_text <- df[!is.na(df$text) & nchar(df$text) > 20, ]
  if (nrow(df_text) == 0) return(character(0))

  # Prefer neutral-to-positive (not purely negative rant, not purely sycophantic)
  df_text <- df_text[df_text$rating >= 0, ]
  if (nrow(df_text) == 0) df_text <- df[!is.na(df$text) & nchar(df$text) > 20, ]

  # Sort by length (longer = more detailed = more actionable)
  df_text$text_len <- nchar(df_text$text)
  df_text <- df_text[order(-df_text$text_len), ]

  head(df_text$text, top_n)
}

# Render word cloud as styled HTML spans
render_wordcloud_html <- function(texts, sentiment_filter = "positive", max_words = 40) {
  freq_df <- get_word_frequencies(texts, top_n = max_words)
  if (nrow(freq_df) == 0) {
    return(tags$p("No text data available.", style = "color:#64748b; text-align:center; padding:30px;"))
  }

  max_freq <- max(freq_df$freq)
  min_freq <- min(freq_df$freq)

  color_palettes <- list(
    positive = c("#10b981", "#34d399", "#6ee7b7", "#a7f3d0", "#06b6d4", "#67e8f9"),
    negative = c("#ef4444", "#f87171", "#fca5a5", "#fb923c", "#fbbf24", "#f59e0b")
  )
  palette <- color_palettes[[sentiment_filter]]

  spans <- lapply(seq_len(nrow(freq_df)), function(i) {
    word <- freq_df$word[i]
    freq <- freq_df$freq[i]
    size_em <- 0.85 + ((freq - min_freq) / max(max_freq - min_freq, 1)) * 2.2
    color <- palette[((i - 1) %% length(palette)) + 1]
    tags$span(word,
      style = sprintf(
        "font-size:%.2frem; color:%s; font-weight:600; padding:4px 6px; display:inline-block; transition:transform 0.2s; cursor:default;",
        size_em, color
      ),
      onmouseover = "this.style.transform='scale(1.2)'",
      onmouseout  = "this.style.transform='scale(1)'"
    )
  })

  div(style = "display:flex; flex-wrap:wrap; justify-content:center; align-items:center; gap:6px; padding:15px; min-height:180px;",
    spans)
}

# Run multi-class / binary NLP predictions using SVM and Logistic Regression models
predict_feedback <- function(text, bundle) {
  # Clean the input text
  cleaned <- clean_text_nlp(text)
  if (cleaned == "") {
    return(list(
      aspect = "teaching",
      sentiment = 0L,
      emotion = "neutral"
    ))
  }
  
  # Helper to convert text into a document-term vector matching features list
  make_feature_vector <- function(clean_text, features) {
    words <- unlist(strsplit(clean_text, "\\s+"))
    word_counts <- table(words)
    
    vec <- numeric(length(features))
    names(vec) <- features
    
    # Fill word counts for features that exist in the text
    matching <- intersect(names(word_counts), features)
    if (length(matching) > 0) {
      vec[matching] <- as.numeric(word_counts[matching])
    }
    
    # Predict in caret/e1071/nnet expects a data.frame matching features
    df <- as.data.frame(t(vec))
    colnames(df) <- features
    df
  }
  
  # Predict Aspect
  asp_vec <- make_feature_vector(cleaned, bundle$aspect_features)
  asp_pred <- as.character(predict(bundle$aspect_model, asp_vec))
  
  # Predict Sentiment
  sent_vec <- make_feature_vector(cleaned, bundle$sent_features)
  sent_pred <- as.character(predict(bundle$sentiment_model, sent_vec))
  sent_val <- as.integer(sent_pred)
  
  # Predict Emotion
  emotion_vec <- make_feature_vector(cleaned, bundle$kaggle_features)
  emo_pred <- as.character(predict(bundle$emotion_model, emotion_vec))
  
  list(
    aspect = asp_pred,
    sentiment = sent_val,
    emotion = emo_pred
  )
}
