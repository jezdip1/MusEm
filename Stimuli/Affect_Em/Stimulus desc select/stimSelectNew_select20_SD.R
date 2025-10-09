# MAIN SELECTION SCRIPT
# Load required libraries
library(dplyr)
library(tidyr)

# Function to calculate typicality scores as per Eerola.
calculate_typicality <- function(data) {
  data %>%
    rowwise() %>%
    mutate(
      # Calculate mean of other emotions for each emotion
      happy_others_mean = mean(c(fear, sad, tender)),
      sad_others_mean = mean(c(fear, happy, tender)),
      fear_others_mean = mean(c(happy, sad, tender)),
      tender_others_mean = mean(c(fear, happy, sad)),
      
      # Calculate typicality scores (emotion rating minus mean of others)
      happy_typicality = happy - happy_others_mean,
      sad_typicality = sad - sad_others_mean,
      fear_typicality = fear - fear_others_mean,
      tender_typicality = tender - tender_others_mean,
      
      # Calculate distance from neutral point (5,5) in valence-energy space
      neutrality = sqrt((valence - 5)^2 + (energy - 5)^2)
    ) %>%
    ungroup()
}

# Function to identify candidate stimuli for each emotion category
identify_candidates <- function(data, emotion_col, typicality_col, 
                                n_high = 4, n_moderate = 4, 
                                moderate_start_prop = 0.14) {  # 14% from top
  
  total_rows <- nrow(data)
  moderate_start <- ceiling(total_rows * moderate_start_prop)
  moderate_end <- moderate_start + (n_moderate - 1)
  
  # Ensure we don't exceed data bounds
  moderate_end <- min(moderate_end, total_rows)
  
  # Sort by typicality score
  sorted_data <- data %>%
    arrange(desc(!!sym(typicality_col)))
  
  # Select high examples (from top)
  high_examples <- sorted_data %>%
    slice_head(n = n_high) %>%
    mutate(category = "high")
  
  # Select moderate examples (from ~14% position)
  moderate_examples <- sorted_data %>%
    slice(moderate_start:moderate_end) %>%
    mutate(category = "moderate")
  
  bind_rows(high_examples, moderate_examples)
}

# Identify neutral candidates
identify_neutral <- function(data, n_high = 4, n_moderate = 4) {
  neutral_data <- data %>%
    mutate(
      # Calculate maximum typicality across emotions
      max_typicality = pmax(happy_typicality, sad_typicality, 
                            fear_typicality, tender_typicality),
      # Calculate average typicality
      avg_typicality = (happy_typicality + sad_typicality + 
                          fear_typicality + tender_typicality) / 4
    ) %>%
    # Filter for stimuli with low maximum typicality and close to neutral point
    filter(
      max_typicality < quantile(max_typicality, 0.5),  # Below median typicality
      abs(avg_typicality) < 1,  # Average typicality close to 0
      neutrality < median(neutrality)  # Closer to neutral point in valence-energy space
    ) %>%
    # Add neutral as max_emotion
    mutate(max_emotion = "neutral") %>%
    # Sort by combination of low typicality and neutrality
    arrange(max_typicality + neutrality)
  
  if(nrow(neutral_data) < (n_high + n_moderate)) {
    warning(paste("Only found", nrow(neutral_data), "neutral candidates"))
    return(NULL)
  }
  
  # Select examples
  high_examples <- neutral_data %>%
    slice_head(n = n_high) %>%
    mutate(category = "high")
  
  moderate_examples <- neutral_data %>%
    slice((n_high + 1):(n_high + n_moderate)) %>%
    mutate(category = "moderate")
  
  bind_rows(high_examples, moderate_examples)
}

# Function to create matched subsets
create_matched_subsets <- function(candidates) {
  subset1 <- data.frame()
  subset2 <- data.frame()
  
  # First, ensure max_emotion column exists
  candidates <- candidates %>%
    rowwise() %>%
    mutate(
      max_emotion = case_when(
        !is.na(max_emotion) & max_emotion == "neutral" ~ "neutral",
        happy_typicality == max(c(happy_typicality, sad_typicality, fear_typicality, tender_typicality)) ~ "happy",
        sad_typicality == max(c(happy_typicality, sad_typicality, fear_typicality, tender_typicality)) ~ "sad",
        fear_typicality == max(c(happy_typicality, sad_typicality, fear_typicality, tender_typicality)) ~ "fear",
        tender_typicality == max(c(happy_typicality, sad_typicality, fear_typicality, tender_typicality)) ~ "tender",
        TRUE ~ NA_character_
      )
    ) %>%
    ungroup()
  
  for(emotion in unique(candidates$max_emotion)) {
    emotion_data <- candidates %>%
      filter(max_emotion == emotion)
    
    for(cat in c("high", "moderate")) {
      cat_data <- emotion_data %>%
        filter(category == cat) %>%
        mutate(
          mean_diff = abs(valence - mean(valence)) +
            abs(energy - mean(energy)) +
            abs(fear - mean(fear)) +
            abs(happy - mean(happy)) +
            abs(sad - mean(sad)) +
            abs(tender - mean(tender))
        ) %>%
        arrange(mean_diff)
      
      if(nrow(cat_data) >= 4) {
        subset1 <- bind_rows(subset1, cat_data[1:2,])
        subset2 <- bind_rows(subset2, cat_data[3:4,])
      }
    }
  }
  
  return(list(subset1 = subset1, subset2 = subset2))
}

# Main analysis function
analyze_emotion_dataset <- function(data) {
  # Calculate typicality scores
  processed_data <- calculate_typicality(data)
  
  # Get candidates for each emotion
  all_candidates <- data.frame()
  
  # Map of emotions to their typicality column names
  emotion_typicality_map <- list(
    happy = "happy_typicality",
    sad = "sad_typicality",
    fear = "fear_typicality",
    tender = "tender_typicality"
  )
  
  # Get candidates for each emotion
  for(emotion in names(emotion_typicality_map)) {
    candidates <- identify_candidates(
      data = processed_data,
      emotion_col = emotion,
      typicality_col = emotion_typicality_map[[emotion]]
    )
    if(!is.null(candidates)) {
      all_candidates <- bind_rows(all_candidates, candidates)
    }
  }
  
  # Get neutral candidates
  neutral_candidates <- identify_neutral(processed_data)
  if(!is.null(neutral_candidates)) {
    all_candidates <- bind_rows(all_candidates, neutral_candidates)
  }
  
  # Create matched subsets
  subsets <- create_matched_subsets(all_candidates)
  
  # Calculate summary statistics
  summary_stats <- bind_rows(
    summarise(subsets$subset1, 
              across(c(valence, energy, fear, happy, sad, tender), 
                     list(mean = mean, sd = sd))) %>%
      mutate(subset = "subset1"),
    summarise(subsets$subset2,
              across(c(valence, energy, fear, happy, sad, tender),
                     list(mean = mean, sd = sd))) %>%
      mutate(subset = "subset2")
  )
  
  # Add counts by category
  category_counts <- bind_rows(
    count(subsets$subset1, max_emotion, category) %>% mutate(subset = "subset1"),
    count(subsets$subset2, max_emotion, category) %>% mutate(subset = "subset2")
  )
  
  # Statistical tests
  rating_vars <- c("valence", "energy", "fear", "happy", "sad", "tender")
  statistical_tests <- list()
  
  combined_data <- bind_rows(
    mutate(subsets$subset1, subset = "subset1"),
    mutate(subsets$subset2, subset = "subset2")
  )
  
  for(var in rating_vars) {
    t_result <- t.test(
      combined_data[[var]] ~ combined_data$subset, 
      var.equal = TRUE
    )
    
    w_result <- wilcox.test(
      combined_data[[var]] ~ combined_data$subset,
      exact = FALSE
    )
    
    subset1_data <- subsets$subset1[[var]]
    subset2_data <- subsets$subset2[[var]]
    
    cohens_d <- (mean(subset1_data) - mean(subset2_data)) / 
      sqrt((sd(subset1_data)^2 + sd(subset2_data)^2) / 2)
    
    statistical_tests[[var]] <- data.frame(
      variable = var,
      t_statistic = t_result$statistic,
      t_p_value = t_result$p.value,
      w_statistic = w_result$statistic,
      w_p_value = w_result$p.value,
      cohens_d = cohens_d,
      mean_diff = mean(subset1_data) - mean(subset2_data),
      subset1_mean = mean(subset1_data),
      subset2_mean = mean(subset2_data),
      subset1_sd = sd(subset1_data),
      subset2_sd = sd(subset2_data)
    )
  }
  
  statistical_tests <- bind_rows(statistical_tests)
  
  return(list(
    subsets = subsets,
    summary_stats = summary_stats,
    category_counts = category_counts,
    statistical_tests = statistical_tests
  ))
}

# Function to export stimuli information to CSV
export_stimuli_info <- function(results, file_path = "selected_stimuli_20.csv") {
  # Combine subsets and add subset indicator
  subset1_data <- results$subsets$subset1 %>%
    mutate(subset = "1")
  
  subset2_data <- results$subsets$subset2 %>%
    mutate(subset = "2")
  
  # Combine the data
  combined_data <- bind_rows(subset1_data, subset2_data)
  
  # Select and organize relevant columns
  export_data <- combined_data %>%
    select(
      Number,
      subset,
      max_emotion,
      category,
      # Emotion ratings
      happy,
      sad,
      tender,
      fear,
      # Typicality scores
      happy_typicality,
      sad_typicality,
      tender_typicality,
      fear_typicality,
      # Neutrality score
      neutrality,
      # Additional metrics
      valence,
      energy
    ) %>%
    # Sort by subset, emotion, and category
    arrange(subset, max_emotion, category)
  
  # Write to CSV
  write.csv(export_data, file = file_path, row.names = FALSE)
  
  cat("Exported", nrow(export_data), "stimuli to", file_path, "\n")
  
  # Return the data frame for inspection
  return(export_data)
}

# MAIN SELECTION RESULTS
# Import data -- load mean_ratings_set2_forR.csv here
data <- read.csv(file.choose(), header = T, sep=';', fileEncoding="UTF-8-BOM")
# Remove duplicate stimuli
data <- data %>% filter(!(Number %in% c(67, 95)))

# Run analysis and check results
results <- analyze_emotion_dataset(data)
View(results$category_counts)
View(results$subsets$subset1)
View(results$subsets$subset2)
View(results$summary_stats)
View(results$statistical_tests)

stimuli_info <- export_stimuli_info(results, "selected_stimuli_20.csv")
View(stimuli_info)

# MAIN SELECTION VISUALIZATION
# Load ggplot for visualizations
library(ggplot2)

# Combine subsets and add subset indicator
plot_data <- bind_rows(
  mutate(results$subsets$subset1, subset = "Subset 1"),
  mutate(results$subsets$subset2, subset = "Subset 2")
)

# Define color scheme for emotions
emotion_colors <- c(
  "happy" = "#FFA500",   # Orange
  "sad" = "#0066CC",     # Blue
  "fear" = "#800080",    # Purple
  "tender" = "#4CAF50",  # Green
  "neutral" = "#404040"  # Darker grey
)

# Create the circumplex plot
ggplot(plot_data, aes(x = valence, y = energy, 
                      color = max_emotion, 
                      shape = subset)) +
  geom_vline(xintercept = 5, linetype = "dashed", alpha = 0.3) +
  geom_hline(yintercept = 5, linetype = "dashed", alpha = 0.3) +
  geom_point(size = 3, alpha = 0.8) +
  scale_color_manual(values = emotion_colors,
                     name = "Emotion Category",
                     labels = c("Fear", "Happy", "Neutral", "Sad", "Tender")) +
  scale_shape_manual(values = c(16, 17),  # Filled circle and triangle
                     name = "Subset") +
  scale_x_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
  scale_y_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
  labs(x = "Valence", 
       y = "Arousal",
       title = "Stimuli in the Valence-Arousal Circumplex (n = 40)") +
  theme_minimal() +
  theme(
    text = element_text(family = "Arial"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    legend.position = "right",
    plot.title = element_text(face = "plain"),
    axis.title = element_text(face = "plain"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    axis.line = element_blank()  # Remove axis lines since we have a frame
  )

ggsave("emotion_circumplex_40.png", width = 6, height = 5, bg = "white", dpi = 300)

# VARIABILITY CHECKS.
# Function to combine mean and SD data
combine_data <- function(mean_data, sd_data) {
  # Ensure a common identifier column
  if(!"Number" %in% colnames(sd_data)) {
    if("Track" %in% colnames(sd_data)) {
      sd_data <- sd_data %>% rename(Number = Track)
    } else {
      stop("No matching ID column found in SD data.")
    }
  }
  
  # Join the datasets
  combined <- mean_data %>%
    left_join(sd_data, by = "Number")
  
  return(combined)
}

# Variability analysis function
analyze_rating_variability <- function(results, sd_data) {
  # Select emotion dimensions
  emotion_sd_cols <- c("Fear_SD", "Happy_SD", "Sad_SD", "Tender_SD")
  
  # Combine data for each subset
  subset1_with_sd <- combine_data(results$subsets$subset1, sd_data)
  subset2_with_sd <- combine_data(results$subsets$subset2, sd_data)
  
  # Combine all data
  all_data <- bind_rows(
    subset1_with_sd %>% mutate(subset = "Subset 1"),
    subset2_with_sd %>% mutate(subset = "Subset 2")
  )
  
  # 1. Compare variability between subsets
  subset1_values <- subset1_with_sd %>% 
    select(all_of(emotion_sd_cols)) %>% 
    unlist(use.names = FALSE)
  
  subset2_values <- subset2_with_sd %>% 
    select(all_of(emotion_sd_cols)) %>% 
    unlist(use.names = FALSE)
  
  subset_comparison <- data.frame(
    subset = c("Subset 1", "Subset 2"),
    mean_sd = c(
      mean(subset1_values, na.rm = TRUE),
      mean(subset2_values, na.rm = TRUE)
    )
  )
  
  # T-test comparing subsets
  subset_ttest <- t.test(subset1_values, subset2_values)
  
  # 2. Calculate variability by emotion category
  emotion_variability <- all_data %>%
    group_by(max_emotion) %>%
    summarise(across(all_of(emotion_sd_cols), ~mean(., na.rm = TRUE)),
              n = n(),
              .groups = "drop") %>%
    mutate(mean_emotional_sd = rowMeans(select(., all_of(emotion_sd_cols)), na.rm = TRUE))
  
  # Extract neutral values for testing
  neutral_values <- all_data %>% 
    filter(max_emotion == "neutral") %>% 
    select(all_of(emotion_sd_cols)) %>% 
    unlist(use.names = FALSE)
  
  # 2. Compare neutral vs. all other emotions combined
  other_values <- all_data %>% 
    filter(max_emotion != "neutral") %>% 
    select(all_of(emotion_sd_cols)) %>% 
    unlist(use.names = FALSE)
  
  combined_comparison <- data.frame(
    category = c("neutral", "all_other_emotions"),
    mean_sd = c(
      mean(neutral_values, na.rm = TRUE),
      mean(other_values, na.rm = TRUE)
    )
  )
  
  # T-test comparing neutral vs all other emotions
  neutral_vs_all_ttest <- t.test(neutral_values, other_values)
  
  # 3. Compare neutral vs. each emotion category
  individual_comparisons <- data.frame()
  
  for(emotion in unique(all_data$max_emotion[all_data$max_emotion != "neutral"])) {
    # Get values for this emotion
    emotion_values <- all_data %>%
      filter(max_emotion == emotion) %>%
      select(all_of(emotion_sd_cols)) %>%
      unlist(use.names = FALSE)
    
    # Run t-test
    t_result <- t.test(neutral_values, emotion_values)
    
    # Add to comparison dataframe
    individual_comparisons <- rbind(individual_comparisons, data.frame(
      emotion = emotion,
      neutral_mean = mean(neutral_values, na.rm = TRUE),
      emotion_mean = mean(emotion_values, na.rm = TRUE),
      difference = mean(neutral_values, na.rm = TRUE) - mean(emotion_values, na.rm = TRUE),
      t_statistic = t_result$statistic,
      p_value = t_result$p.value
    ))
  }
  
  # Return results
  return(list(
    # 1. Subset comparison
    subset_comparison = list(
      data = subset_comparison,
      t_test = subset_ttest
    ),
    # 2. Neutral vs all emotions combined
    neutral_vs_all = list(
      data = combined_comparison,
      t_test = neutral_vs_all_ttest
    ),
    # 3. Neutral vs each emotion category
    neutral_vs_each = individual_comparisons,
    # Additional data
    emotion_variability = emotion_variability
  ))
}

# Data loading and analysis -- load FIN_merged_summary.csv here
sd_data <- read.csv(file.choose(), header = T, fileEncoding="UTF-8-BOM")
variability_results <- analyze_rating_variability(results, sd_data)

# Subset comparison
print(variability_results$subset_comparison$data)
print(variability_results$subset_comparison$t_test)

# Neutral vs. all other emotions comparison
print(variability_results$neutral_vs_all$data)
print(variability_results$neutral_vs_all$t_test)

# Neutral vs. each other emotion comparison
print(variability_results$neutral_vs_each)
