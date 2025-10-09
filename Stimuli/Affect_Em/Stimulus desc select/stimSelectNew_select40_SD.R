# MAIN SELECTION SCRIPT
# Load required libraries
library(dplyr)
library(tidyr)

# Function to calculate typicality scores for the extended selection
calculate_typicality_40 <- function(data) {
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

# Modified identify candidates function to ensure enough unique stimuli
identify_candidates_40 <- function(data, emotion_col, typicality_col, 
                                   n_high = 8, n_moderate = 8,
                                   existing_stimuli) {
  
  # Remove existing stimuli from consideration
  new_data <- data %>%
    filter(!Number %in% existing_stimuli$Number)
  
  # Sort by typicality score
  sorted_data <- new_data %>%
    arrange(desc(!!sym(typicality_col)))
  
  # Select high examples with buffer
  high_examples <- sorted_data %>%
    slice_head(n = n_high * 1.5) %>%  # Get more candidates than needed
    arrange(desc(!!sym(emotion_col))) %>%  # Sort by actual emotion rating
    slice_head(n = n_high) %>%  # Take top n_high
    mutate(category = "high")
  
  # Select moderate examples from remaining data
  remaining_data <- sorted_data %>%
    filter(!Number %in% high_examples$Number) %>%
    # Take a larger slice for moderate examples
    slice((n_high + 1):(n() * 0.5))  # Use half of remaining data
  
  moderate_examples <- remaining_data %>%
    arrange(desc(!!sym(emotion_col))) %>%
    slice_head(n = n_moderate) %>%
    mutate(category = "moderate")
  
  candidates <- bind_rows(high_examples, moderate_examples) %>%
    distinct(Number, .keep_all = TRUE)
  
  # Verify enough stimuli
  if(nrow(candidates) < (n_high + n_moderate)) {
    warning(sprintf("Only found %d stimuli for %s (needed %d)", 
                    nrow(candidates), emotion_col, n_high + n_moderate))
  }
  
  return(candidates)
}

# Modified identify neutral candidates function to ensure enough unique stimuli
identify_neutral_40 <- function(data, n_high = 8, n_moderate = 8, 
                                existing_neutral) {
  # Remove existing neutral stimuli
  new_data <- data %>%
    filter(!Number %in% existing_neutral$Number)
  
  neutral_data <- new_data %>%
    mutate(
      max_typicality = pmax(happy_typicality, sad_typicality, 
                            fear_typicality, tender_typicality),
      avg_typicality = (happy_typicality + sad_typicality + 
                          fear_typicality + tender_typicality) / 4
    ) %>%
    filter(
      max_typicality < quantile(max_typicality, 0.6),  # Relaxed threshold
      abs(avg_typicality) < 1.2,  # Relaxed threshold
      neutrality < median(neutrality) * 1.2  # Relaxed threshold
    ) %>%
    mutate(max_emotion = "neutral") %>%
    arrange(max_typicality + neutrality)
  
  if(nrow(neutral_data) < (n_high + n_moderate)) {
    warning(paste("Only found", nrow(neutral_data), "additional neutral candidates"))
    return(NULL)
  }
  
  # Select with buffer
  high_candidates <- neutral_data %>%
    slice_head(n = n_high * 1.5) %>%
    arrange(neutrality) %>%
    slice_head(n = n_high) %>%
    mutate(category = "high")
  
  moderate_candidates <- neutral_data %>%
    filter(!Number %in% high_candidates$Number) %>%
    slice_head(n = n_moderate * 1.5) %>%
    arrange(neutrality) %>%
    slice_head(n = n_moderate) %>%
    mutate(category = "moderate")
  
  bind_rows(high_candidates, moderate_candidates) %>%
    distinct(Number, .keep_all = TRUE)
}

# Function to create matched subsets and prevent duplicates
create_matched_subsets_40 <- function(candidates, existing_subset1, existing_subset2) {
  # Start with existing subsets
  subset1 <- existing_subset1
  subset2 <- existing_subset2
  
  # Process new candidates
  new_candidates <- candidates %>%
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
    ungroup() %>%
    # Remove any stimuli that are already in existing subsets
    filter(!Number %in% c(subset1$Number, subset2$Number)) %>%
    # Remove any duplicates within new candidates
    distinct(Number, .keep_all = TRUE)
  
  for(emotion in unique(new_candidates$max_emotion)) {
    emotion_data <- new_candidates %>%
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
        arrange(mean_diff) %>%
        # Ensure no duplicates
        distinct(Number, .keep_all = TRUE)
      
      if(nrow(cat_data) >= 4) {
        new_subset1 <- cat_data[1:2,]
        new_subset2 <- cat_data[3:4,]
        
        # Only add if not already present
        subset1 <- bind_rows(subset1,
                             filter(new_subset1, !Number %in% subset1$Number))
        subset2 <- bind_rows(subset2,
                             filter(new_subset2, !Number %in% subset2$Number))
      }
    }
  }
  
  # Final check for duplicates
  subset1 <- subset1 %>% distinct(Number, .keep_all = TRUE)
  subset2 <- subset2 %>% distinct(Number, .keep_all = TRUE)
  
  # Verify counts
  cat("Subset 1 total stimuli:", nrow(subset1), "\n")
  cat("Subset 2 total stimuli:", nrow(subset2), "\n")
  cat("Subset 1 unique stimuli:", n_distinct(subset1$Number), "\n")
  cat("Subset 2 unique stimuli:", n_distinct(subset2$Number), "\n")
  
  return(list(subset1 = subset1, subset2 = subset2))
}

# Main analysis function
analyze_emotion_dataset_40 <- function(data, existing_results) {
  # Get original numbers
  original_numbers <- c(existing_results$subsets$subset1$Number,
                        existing_results$subsets$subset2$Number)
  
  # Get remaining data
  remaining_data <- data %>%
    filter(!Number %in% original_numbers) %>%
    distinct(Number, .keep_all = TRUE)
  
  # Calculate typicality scores for remaining data
  processed_data <- calculate_typicality_40(remaining_data)
  
  # Get original distribution
  original_dist <- bind_rows(
    existing_results$subsets$subset1,
    existing_results$subsets$subset2
  ) %>%
    count(max_emotion, category)
  
  # Initialize new candidates dataframe
  new_candidates <- data.frame()
  used_numbers <- original_numbers
  
  # For each emotion category and intensity
  for(emotion in unique(original_dist$max_emotion)) {
    for(cat in c("high", "moderate")) {
      n_needed <- original_dist %>%
        filter(max_emotion == emotion, category == cat) %>%
        pull(n)
      
      if(emotion != "neutral") {
        candidates <- processed_data %>%
          filter(!Number %in% used_numbers) %>%
          mutate(
            this_typicality = get(paste0(emotion, "_typicality"))
          ) %>%
          arrange(desc(this_typicality)) %>%
          head(n_needed * 3) %>%
          mutate(
            max_emotion = emotion,
            category = cat
          ) %>%
          arrange(desc(get(emotion))) %>%
          head(n_needed)
      } else {
        candidates <- processed_data %>%
          filter(!Number %in% used_numbers) %>%
          mutate(
            max_typicality = pmax(happy_typicality, sad_typicality,
                                  fear_typicality, tender_typicality)
          ) %>%
          filter(max_typicality < median(max_typicality)) %>%
          arrange(neutrality) %>%
          head(n_needed) %>%
          mutate(
            max_emotion = "neutral",
            category = cat
          )
      }
      
      used_numbers <- c(used_numbers, candidates$Number)
      new_candidates <- bind_rows(new_candidates, candidates)
    }
  }
  
  # Split new candidates into subsets
  new_subset1 <- data.frame()
  new_subset2 <- data.frame()
  
  for(emotion in unique(new_candidates$max_emotion)) {
    for(cat in c("high", "moderate")) {
      current_data <- new_candidates %>%
        filter(max_emotion == emotion, category == cat) %>%
        distinct(Number, .keep_all = TRUE)
      
      n_per_subset <- nrow(current_data) / 2
      if(n_per_subset > 0) {
        new_subset1 <- bind_rows(new_subset1, current_data[1:n_per_subset,])
        new_subset2 <- bind_rows(new_subset2, current_data[(n_per_subset+1):nrow(current_data),])
      }
    }
  }
  
  # Combine with original subsets
  final_subset1 <- bind_rows(
    existing_results$subsets$subset1,
    new_subset1
  ) %>% distinct(Number, .keep_all = TRUE)
  
  final_subset2 <- bind_rows(
    existing_results$subsets$subset2,
    new_subset2
  ) %>% distinct(Number, .keep_all = TRUE)
  
  # Calculate statistics and return results
  combined_data <- bind_rows(
    mutate(final_subset1, subset = "subset1"),
    mutate(final_subset2, subset = "subset2")
  )
  
  rating_vars <- c("valence", "energy", "fear", "happy", "sad", "tender")
  statistical_tests <- list()
  
  for(var in rating_vars) {
    t_result <- t.test(
      combined_data[[var]] ~ combined_data$subset, 
      var.equal = TRUE
    )
    
    w_result <- wilcox.test(
      combined_data[[var]] ~ combined_data$subset,
      exact = FALSE
    )
    
    subset1_data <- final_subset1[[var]]
    subset2_data <- final_subset2[[var]]
    
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
  
  return(list(
    subsets = list(subset1 = final_subset1, subset2 = final_subset2),
    summary_stats = bind_rows(
      summarise(final_subset1, 
                across(c(valence, energy, fear, happy, sad, tender), 
                       list(mean = mean, sd = sd))) %>%
        mutate(subset = "subset1"),
      summarise(final_subset2,
                across(c(valence, energy, fear, happy, sad, tender),
                       list(mean = mean, sd = sd))) %>%
        mutate(subset = "subset2")
    ),
    category_counts = bind_rows(
      count(final_subset1, max_emotion, category) %>% mutate(subset = "subset1"),
      count(final_subset2, max_emotion, category) %>% mutate(subset = "subset2")
    ),
    statistical_tests = bind_rows(statistical_tests)
  ))
}

# Function to export extended stimuli information to CSV
export_stimuli_info_40 <- function(results_40, file_path = "selected_stimuli_40.csv") {
  # Combine subsets and add subset indicator
  subset1_data <- results_40$subsets$subset1 %>%
    mutate(subset = "1")
  
  subset2_data <- results_40$subsets$subset2 %>%
    mutate(subset = "2")
  
  # Combine the data
  combined_data <- bind_rows(subset1_data, subset2_data)
  
  # Get original stimulus numbers if they exist in the environment
  if(exists("results")) {
    original_numbers <- c(results$subsets$subset1$Number, 
                          results$subsets$subset2$Number)
    combined_data <- combined_data %>%
      mutate(is_original = Number %in% original_numbers)
  } else {
    combined_data <- combined_data %>%
      mutate(is_original = NA)
  }
  
  # Select and organize relevant columns
  export_data <- combined_data %>%
    # Include ID/Number column
    select(
      Number,
      subset,
      is_original,
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
    # Sort by subset, emotion, category and original/new status
    arrange(subset, is_original, max_emotion, category)
  
  # Write to CSV
  write.csv(export_data, file = file_path, row.names = FALSE)
  
  cat("Exported", nrow(export_data), "stimuli to", file_path, "\n")
  
  # Return the data frame for inspection
  return(export_data)
}

# MAIN SELECTION RESULTS
# Remove more duplicate stimuli
data <- data %>% filter(!(Number %in% c(24, 34, 22, 19)))

# Run analysis, check and export results -- ensure that the results object is in the environment
results_40 <- analyze_emotion_dataset_40(data, results)
View(results_40$category_counts)
View(results_40$subsets$subset1)
View(results_40$subsets$subset2)
View(results_40$summary_stats)
View(results_40$statistical_tests)

stimuli_info_40 <- export_stimuli_info_40(results_40, "selected_stimuli_40.csv")
View(stimuli_info_40)

# MAIN SELECTION VISUALIZATION -- new old legend not working
# Load ggplot
library(ggplot2)

# Get original stimulus numbers
original_numbers <- c(results$subsets$subset1$Number, 
                      results$subsets$subset2$Number)

# Prepare plot data
plot_data_40 <- bind_rows(
  mutate(results_40$subsets$subset1, subset = "Subset 1"),
  mutate(results_40$subsets$subset2, subset = "Subset 2")
) %>%
  mutate(is_original = Number %in% original_numbers)

# Define color scheme
emotion_colors <- c(
  "happy" = "#FFA500",   # Orange
  "sad" = "#0066CC",     # Blue
  "fear" = "#800080",    # Purple
  "tender" = "#4CAF50",  # Green
  "neutral" = "#404040"  # Darker grey
)

# Create a custom legend for selection type
selection_legend <- data.frame(
  x = c(1.5, 1.5),
  y = c(1.3, 1.1),
  label = c("Original (filled)", "New (hollow)"),
  shape = c(21, 21),
  fill = c("black", NA)
)

# Create the plot
ggplot() +
  # Add reference lines
  geom_vline(xintercept = 5, linetype = "dashed", alpha = 0.3) +
  geom_hline(yintercept = 5, linetype = "dashed", alpha = 0.3) +
  # Plot new stimuli first (open shapes)
  geom_point(data = filter(plot_data_40, !is_original),
             aes(x = valence, y = energy, 
                 color = max_emotion,
                 shape = subset),
             size = 3,
             fill = NA) +
  # Plot original stimuli on top (filled shapes)
  geom_point(data = filter(plot_data_40, is_original),
             aes(x = valence, y = energy, 
                 color = max_emotion,
                 fill = max_emotion,
                 shape = subset),
             size = 3) +
  # Set scales and labels
  scale_color_manual(values = emotion_colors,
                     name = "Emotion Category",
                     labels = c("Fear", "Happy", "Neutral", "Sad", "Tender")) +
  scale_fill_manual(values = emotion_colors,
                    guide = "none") +
  scale_shape_manual(values = c("Subset 1" = 21, "Subset 2" = 24),
                     name = "Subset") +
  scale_x_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
  scale_y_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
  labs(x = "Valence", 
       y = "Arousal",
       title = "Stimuli in the Valence-Arousal Circumplex (n = 80)") +
  theme_minimal() +
  theme(
    text = element_text(family = "Arial"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    legend.position = "right",
    legend.box = "vertical",
    plot.title = element_text(face = "plain"),
    axis.title = element_text(face = "plain"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    axis.line = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

ggsave("emotion_circumplex_40.png", width = 6, height = 5, dpi = 300, bg = "white")

# VARIABILITY CHECKS FOR THE EXTENDED DATASET.
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

# Variability analysis function for the extended dataset
analyze_rating_variability_40 <- function(results_40, sd_data) {
  # Select emotion dimensions
  emotion_sd_cols <- c("Fear_SD", "Happy_SD", "Sad_SD", "Tender_SD")
  
  # Combine data for each subset
  subset1_with_sd <- combine_data(results_40$subsets$subset1, sd_data)
  subset2_with_sd <- combine_data(results_40$subsets$subset2, sd_data)
  
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
variability_results_40 <- analyze_rating_variability_40(results_40, sd_data)

# Subset comparison
print(variability_results_40$subset_comparison$data)
print(variability_results_40$subset_comparison$t_test)

# Neutral vs. all other emotions comparison
print(variability_results_40$neutral_vs_all$data)
print(variability_results_40$neutral_vs_all$t_test)

# Neutral vs. each other emotion comparison
print(variability_results_40$neutral_vs_each)
