# helpers/export.R
# Export helpers: CSV downloads and native R PDF summary reports

library(shiny)
library(ggplot2)
library(grid)

# CSV Download Handler factory
csv_download_handler <- function(data_fn, filename_prefix = "sentilytics_export") {
  downloadHandler(
    filename = function() {
      sprintf("%s_%s.csv", filename_prefix, format(Sys.Date(), "%Y%m%d"))
    },
    content = function(file) {
      df <- data_fn()
      write.csv(df, file, row.names = FALSE)
    }
  )
}

# PDF Summary Report Download Handler using ggplot2 & Grid layout
pdf_report_handler <- function(data_fn, title = "Sentilytics Campus Sentiment Report") {
  downloadHandler(
    filename = function() {
      sprintf("sentilytics_report_%s.pdf", format(Sys.Date(), "%Y%m%d"))
    },
    content = function(file) {
      df <- data_fn()

      # Compute summary stats
      total <- nrow(df)
      pos <- sum(df$rating == 1, na.rm = TRUE)
      neu <- sum(df$rating == 0, na.rm = TRUE)
      neg <- sum(df$rating == -1, na.rm = TRUE)
      pos_pct <- if (total > 0) round(pos/total*100, 1) else 0
      neg_pct <- if (total > 0) round(neg/total*100, 1) else 0

      # Set up PDF graphics device
      pdf(file, width = 8.5, height = 11)
      on.exit(dev.off(), add = TRUE)

      # ── 1. Main Header Annotation Plot ──
      p_header <- ggplot() +
        annotate("rect", xmin = 0, xmax = 10, ymin = 4, ymax = 10, fill = "#1e293b") +
        annotate("text", x = 5, y = 7.5, label = title, color = "white", size = 6, fontface = "bold", hjust = 0.5) +
        annotate("text", x = 5, y = 5.2, label = sprintf("Generated on %s | Sentilytics Feedback System", format(Sys.time(), "%B %d, %Y at %H:%M")), color = "#94a3b8", size = 3.5, hjust = 0.5) +
        xlim(0, 10) + ylim(0, 10) +
        theme_void() +
        theme(plot.margin = margin(0,0,0,0))

      # ── 2. KPI Summary Boxes ──
      p_kpi <- ggplot() +
        # Total Box
        annotate("rect", xmin = 0.5, xmax = 2.5, ymin = 2, ymax = 8, fill = "#f8fafc", color = "#e2e8f0", size = 1) +
        annotate("text", x = 1.5, y = 6, label = as.character(total), size = 6, fontface = "bold", color = "#1e293b") +
        annotate("text", x = 1.5, y = 4, label = "Total Reviews", size = 3, fontface = "bold", color = "#64748b") +

        # Positive Box
        annotate("rect", xmin = 2.8, xmax = 4.8, ymin = 2, ymax = 8, fill = "#f8fafc", color = "#e2e8f0", size = 1) +
        annotate("text", x = 3.8, y = 6, label = sprintf("%.1f%%", pos_pct), size = 6, fontface = "bold", color = "#10b981") +
        annotate("text", x = 3.8, y = 4, label = "Positive Rate", size = 3, fontface = "bold", color = "#64748b") +

        # Negative Box
        annotate("rect", xmin = 5.1, xmax = 7.1, ymin = 2, ymax = 8, fill = "#f8fafc", color = "#e2e8f0", size = 1) +
        annotate("text", x = 6.1, y = 6, label = sprintf("%.1f%%", neg_pct), size = 6, fontface = "bold", color = "#ef4444") +
        annotate("text", x = 6.1, y = 4, label = "Negative Rate", size = 3, fontface = "bold", color = "#64748b") +

        # Neutral Box
        annotate("rect", xmin = 7.4, xmax = 9.4, ymin = 2, ymax = 8, fill = "#f8fafc", color = "#e2e8f0", size = 1) +
        annotate("text", x = 8.4, y = 6, label = as.character(neu), size = 6, fontface = "bold", color = "#64748b") +
        annotate("text", x = 8.4, y = 4, label = "Neutral Count", size = 3, fontface = "bold", color = "#64748b") +

        xlim(0, 10) + ylim(0, 10) +
        theme_void() +
        theme(plot.margin = margin(0,0,0,0))

      # ── 3. Aspect Sentiment Chart ──
      aspect_labels <- c(
        teaching = "Teaching Quality", coursecontent = "Course Content",
        examination = "Examination", labwork = "Lab Work",
        library_facilities = "Library Facilities", extracurricular = "Extracurricular"
      )

      aspect_data <- data.frame(
        aspect = rep(names(aspect_labels), 3),
        sentiment = rep(c("Positive", "Neutral", "Negative"), each = length(aspect_labels)),
        count = numeric(length(aspect_labels) * 3),
        stringsAsFactors = FALSE
      )

      for (asp in names(aspect_labels)) {
        sub_df <- df[df$aspect == asp, ]
        aspect_data[aspect_data$aspect == asp & aspect_data$sentiment == "Positive", "count"] <- sum(sub_df$rating == 1, na.rm = TRUE)
        aspect_data[aspect_data$aspect == asp & aspect_data$sentiment == "Neutral", "count"] <- sum(sub_df$rating == 0, na.rm = TRUE)
        aspect_data[aspect_data$aspect == asp & aspect_data$sentiment == "Negative", "count"] <- sum(sub_df$rating == -1, na.rm = TRUE)
      }
      aspect_data$label <- aspect_labels[aspect_data$aspect]
      aspect_data$sentiment <- factor(aspect_data$sentiment, levels = c("Negative", "Neutral", "Positive"))

      p_chart <- ggplot(aspect_data, aes(x = label, y = count, fill = sentiment)) +
        geom_bar(stat = "identity", width = 0.55) +
        scale_fill_manual(values = c("Positive" = "#10b981", "Neutral" = "#94a3b8", "Negative" = "#ef4444")) +
        labs(title = "Campus Sentiment Breakdown by Aspect", x = "", y = "Count") +
        theme_minimal() +
        theme(
          plot.title = element_text(face = "bold", size = 12, color = "#1e293b", hjust = 0.5),
          legend.title = element_blank(),
          axis.text.x = element_text(angle = 12, hjust = 1, size = 9, color = "#334155"),
          panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          legend.position = "bottom"
        )

      # ── 4. Aspect Details Table ──
      rows_data <- data.frame(
        Aspect = c("Teaching Quality", "Course Content", "Examination", "Lab Work", "Library Facilities", "Extracurricular"),
        Total = numeric(6),
        Positive = numeric(6),
        Neutral = numeric(6),
        Negative = numeric(6),
        NetScore = character(6),
        stringsAsFactors = FALSE
      )

      aspect_keys <- c("teaching","coursecontent","examination","labwork","library_facilities","extracurricular")
      for (i in seq_along(aspect_keys)) {
        sub_df <- df[df$aspect == aspect_keys[i], ]
        p <- sum(sub_df$rating == 1, na.rm = TRUE)
        n <- sum(sub_df$rating == 0, na.rm = TRUE)
        ng <- sum(sub_df$rating == -1, na.rm = TRUE)
        t <- nrow(sub_df)
        net <- if (t > 0) round(((p - ng) / t) * 100, 1) else 0

        rows_data$Total[i] <- t
        rows_data$Positive[i] <- p
        rows_data$Neutral[i] <- n
        rows_data$Negative[i] <- ng
        rows_data$NetScore[i] <- sprintf("%+.1f%%", net)
      }

      # Base plot for Table
      p_table <- ggplot() +
        # Table Headers
        annotate("rect", xmin = 0, xmax = 10, ymin = 8.8, ymax = 9.8, fill = "#3b82f6") +
        annotate("text", x = 0.5, y = 9.3, label = "Aspect", color = "white", fontface = "bold", size = 3.5, hjust = 0) +
        annotate("text", x = 3.0, y = 9.3, label = "Total", color = "white", fontface = "bold", size = 3.5, hjust = 0.5) +
        annotate("text", x = 4.5, y = 9.3, label = "Positive", color = "white", fontface = "bold", size = 3.5, hjust = 0.5) +
        annotate("text", x = 6.0, y = 9.3, label = "Neutral", color = "white", fontface = "bold", size = 3.5, hjust = 0.5) +
        annotate("text", x = 7.5, y = 9.3, label = "Negative", color = "white", fontface = "bold", size = 3.5, hjust = 0.5) +
        annotate("text", x = 9.0, y = 9.3, label = "Net Score", color = "white", fontface = "bold", size = 3.5, hjust = 0.5)

      # Loop to add row separators and cell texts
      for (r in 1:6) {
        y_pos <- 8.8 - r * 1.2
        row_val <- rows_data[r, ]
        p_table <- p_table +
          annotate("segment", x = 0, xend = 10, y = y_pos - 0.1, yend = y_pos - 0.1, color = "#e2e8f0") +
          annotate("text", x = 0.5, y = y_pos + 0.3, label = row_val$Aspect, size = 3.5, color = "#1e293b", hjust = 0) +
          annotate("text", x = 3.0, y = y_pos + 0.3, label = as.character(row_val$Total), size = 3.5, color = "#475569", hjust = 0.5) +
          annotate("text", x = 4.5, y = y_pos + 0.3, label = as.character(row_val$Positive), size = 3.5, color = "#10b981", hjust = 0.5) +
          annotate("text", x = 6.0, y = y_pos + 0.3, label = as.character(row_val$Neutral), size = 3.5, color = "#475569", hjust = 0.5) +
          annotate("text", x = 7.5, y = y_pos + 0.3, label = as.character(row_val$Negative), size = 3.5, color = "#ef4444", hjust = 0.5) +
          annotate("text", x = 9.0, y = y_pos + 0.3, label = row_val$NetScore, size = 3.8, fontface = "bold", color = "#1e293b", hjust = 0.5)
      }

      # Table Footer & Brand tag
      p_table <- p_table +
        annotate("segment", x = 0, xend = 10, y = 0.3, yend = 0.3, color = "#cbd5e1", size = 1) +
        annotate("text", x = 5, y = 0.05, label = "Sentilytics Feedback Sentiment Analysis Report - Confidential", color = "#94a3b8", size = 3, hjust = 0.5) +
        xlim(0, 10) + ylim(0, 10) +
        theme_void() +
        theme(plot.margin = margin(0,0,0,0))

      # Draw via Grid layout system
      grid.newpage()
      pushViewport(viewport(layout = grid.layout(10, 10)))

      print(p_header, vp = viewport(layout.pos.row = 1:2, layout.pos.col = 1:10))
      print(p_kpi,    vp = viewport(layout.pos.row = 3,   layout.pos.col = 1:10))
      print(p_chart,  vp = viewport(layout.pos.row = 4:6, layout.pos.col = 1:10))
      print(p_table,  vp = viewport(layout.pos.row = 7:10, layout.pos.col = 1:10))
    }
  )
}
