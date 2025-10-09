# MAIN ANALYSIS FUNCTIONS
library(dplyr)
library(ggplot2)

# Read and preprocess data
read_and_preprocess <- function(normalize = TRUE) {
  # Read datasets
  selected <- read.csv("selected_stimuli_40.csv", stringsAsFactors = FALSE)
  imp_set <- read.csv("imp_set_select.csv", stringsAsFactors = FALSE)
  
  # Convert to numeric
  imp_set$instruments_check <- as.numeric(imp_set$instruments_check)
  imp_set$piano_check <- as.numeric(imp_set$piano_check)
  
  # Calculate centrality for selected dataset (standard way)
  selected$centrality <- sqrt((selected$valence - 5)^2 + (selected$energy - 5)^2)
  
  # Store original values for imp_set before normalization
  if(normalize) {
    imp_set$orig_valence <- imp_set$valence
    imp_set$orig_energy <- imp_set$energy
    imp_set$orig_happy <- imp_set$happy
    imp_set$orig_sad <- imp_set$sad
    imp_set$orig_tender <- imp_set$tender
    imp_set$orig_fear <- imp_set$fear
    
    # Calculate original centrality for imp_set before normalization
    imp_set$orig_centrality <- sqrt((imp_set$valence - 5)^2 + (imp_set$energy - 5)^2)
    
    # Emotion and dimension columns to normalize
    emotion_cols <- c("valence", "energy", "happy", "sad", "tender", "fear")
    
    # Apply normalization to map imp_set to the observed range in selected
    for(col in emotion_cols) {
      # Get observed ranges in both datasets
      selected_min <- min(selected[[col]], na.rm = TRUE)
      selected_max <- max(selected[[col]], na.rm = TRUE)
      imp_min <- min(imp_set[[col]], na.rm = TRUE)
      imp_max <- max(imp_set[[col]], na.rm = TRUE)
      
      # Normalize imp_set to match the observed range in selected
      imp_set[[col]] <- selected_min + (imp_set[[col]] - imp_min) * 
        (selected_max - selected_min) / (imp_max - imp_min)
    }
    
    # Calculate standard centrality with normalized values (for reference)
    imp_set$std_centrality <- sqrt((imp_set$valence - 5)^2 + (imp_set$energy - 5)^2)
    
    # Calculate adjusted centrality for imp_set
    # Approach: Scale imp_set centrality to match the range of selected centrality
    selected_centrality_min <- min(selected$centrality, na.rm = TRUE)
    selected_centrality_max <- max(selected$centrality, na.rm = TRUE)
    imp_centrality_min <- min(imp_set$std_centrality, na.rm = TRUE)
    imp_centrality_max <- max(imp_set$std_centrality, na.rm = TRUE)
    
    # Apply the scaling to make centrality comparable between datasets
    imp_set$centrality <- selected_centrality_min + (imp_set$std_centrality - imp_centrality_min) * 
      (selected_centrality_max - selected_centrality_min) / 
      (imp_centrality_max - imp_centrality_min)
  } else {
    # If not normalizing, calculate standard centrality
    imp_set$centrality <- sqrt((imp_set$valence - 5)^2 + (imp_set$energy - 5)^2)
  }
  
  return(list(selected = selected, imp_set = imp_set))
}

# Find matches without duplicates, starting with neutral category
find_matches <- function(selected, imp_set) {
  # Define the order of emotions to process
  emotion_order <- c("neutral", "tender", "sad", "happy", "fear")
  
  # Initialize matches dataframe
  matches <- data.frame()
  
  # Keep track of which imp_set stimuli have already been matched
  used_stimuli <- numeric(0)
  
  # Process emotions in the specified order
  for (current_emotion in emotion_order) {
    # Get all stimuli for this emotion
    emotion_stimuli <- selected %>%
      filter(max_emotion == current_emotion)
    
    # Find matches for each stimulus in this emotion category
    for (i in 1:nrow(emotion_stimuli)) {
      s <- emotion_stimuli[i, ]
      distances <- numeric(nrow(imp_set))
      
      for (j in 1:nrow(imp_set)) {
        # Skip if this stimulus is already used
        if (imp_set$Number_S1[j] %in% used_stimuli) {
          distances[j] <- Inf
          next
        }
        
        # Initialize weights with base values
        weights <- c(1, 1, 1, 1, 1)
        names(weights) <- c("happy", "sad", "tender", "fear", "centrality")
        
        # Apply adjusted weights based on emotion
        if (current_emotion %in% c("happy", "sad", "tender", "fear")) {
          # Triple weight to target emotion, double weight to centrality, single weight elsewhere
          weights[current_emotion] <- 3
          weights["centrality"] <- 2
        } else if (current_emotion == "neutral") {
          # Four times weight to centrality, single weight elsewhere
          weights["centrality"] <- 4
        }
        
        # Calculate weighted squared differences
        sq_diffs <- numeric(5)
        sq_diffs[1] <- ((s$happy - imp_set[j, "happy"])^2) * weights["happy"]
        sq_diffs[2] <- ((s$sad - imp_set[j, "sad"])^2) * weights["sad"]
        sq_diffs[3] <- ((s$tender - imp_set[j, "tender"])^2) * weights["tender"]
        sq_diffs[4] <- ((s$fear - imp_set[j, "fear"])^2) * weights["fear"]
        sq_diffs[5] <- ((s$centrality - imp_set[j, "centrality"])^2) * weights["centrality"]
        
        # Calculate total distance
        distances[j] <- sqrt(sum(sq_diffs, na.rm = TRUE))
      }
      
      # Find the best match that hasn't been used yet
      valid_indices <- which(is.finite(distances))
      
      best_match_idx <- valid_indices[which.min(distances[valid_indices])]
      match_row <- imp_set[best_match_idx, ]
      
      # Mark this imp_set stimulus as used
      used_stimuli <- c(used_stimuli, match_row$Number_S1)
      
      # Add match info with all requested values
      match_data <- data.frame(
        # Original stimulus info
        Number_S2 = s$Number_S2,
        subset = s$subset,
        max_emotion = s$max_emotion,
        category = s$category,
        
        # Match info
        Number_S1 = match_row$Number_S1,
        distance = distances[best_match_idx], 
        
        # Original ratings (1-9 scale)
        S2_happy = s$happy,
        S2_sad = s$sad,
        S2_tender = s$tender,
        S2_fear = s$fear,
        S2_valence = s$valence,
        S2_energy = s$energy,
        S2_centrality = s$centrality,
        
        # Match ratings (normalized)
        S1_happy = match_row$happy,
        S1_sad = match_row$sad,
        S1_tender = match_row$tender,
        S1_fear = match_row$fear,
        S1_valence = match_row$valence,
        S1_energy = match_row$energy,
        S1_centrality = match_row$centrality,
        
        # Check values for later filtering
        instruments_check = match_row$instruments_check,
        piano_check = match_row$piano_check,
        
        stringsAsFactors = FALSE
      )
      
      matches <- rbind(matches, match_data)
    }
  }
  
  return(matches)
}

# Function 1: Select piano=1 and instruments=0 stimuli
select_initial_stimuli <- function(matches, max_per_emotion_category = 2) {
  # Initialize results
  piano_stimuli <- c()
  instruments_stimuli <- c()
  piano_distribution <- matrix(0, nrow = 5, ncol = 2)
  instruments_distribution <- matrix(0, nrow = 5, ncol = 2)
  
  # Set row and column names for distribution matrices
  rownames(piano_distribution) <- c("happy", "sad", "tender", "fear", "neutral")
  colnames(piano_distribution) <- c("high", "moderate")
  rownames(instruments_distribution) <- c("happy", "sad", "tender", "fear", "neutral")
  colnames(instruments_distribution) <- c("high", "moderate")
  
  # List of emotions to ensure at least one per category
  emotions <- c("happy", "sad", "tender", "fear", "neutral")
  
  # STEP 1: Select instruments=0 stimuli (up to 10)
  # First pass: ensure at least one per emotion
  for (emotion in emotions) {
    # Find best match for this emotion (either category)
    best_candidate <- matches %>%
      filter(!is.na(instruments_check), instruments_check == 0, max_emotion == emotion) %>%
      arrange(distance) %>%
      head(1)
    
    if (nrow(best_candidate) > 0) {
      # Add to selection
      instruments_stimuli <- c(instruments_stimuli, best_candidate$Number_S1)
      
      # Update distribution
      category <- best_candidate$category
      instruments_distribution[emotion, category] <- instruments_distribution[emotion, category] + 1
    }
  }
  
  # Second pass: fill up to 10 total
  remaining_slots <- 10 - length(instruments_stimuli)
  if (remaining_slots > 0) {
    instruments_candidates <- matches %>%
      filter(!is.na(instruments_check), instruments_check == 0,
             !(Number_S1 %in% instruments_stimuli)) %>%
      arrange(distance)
    
    # Process each candidate
    for (i in 1:nrow(instruments_candidates)) {
      if (length(instruments_stimuli) >= 10) break
      
      candidate <- instruments_candidates[i, ]
      emotion <- candidate$max_emotion
      category <- candidate$category
      
      # Check if we've reached the maximum for this emotion-category
      if (instruments_distribution[emotion, category] < max_per_emotion_category) {
        # Add to selection
        instruments_stimuli <- c(instruments_stimuli, candidate$Number_S1)
        
        # Update distribution
        instruments_distribution[emotion, category] <- instruments_distribution[emotion, category] + 1
      }
    }
  }
  
  # STEP 2: Select piano=1 stimuli (up to 10)
  # First pass: ensure at least one per emotion
  for (emotion in emotions) {
    # Skip if we already have enough from this emotion (across both tasks)
    if (sum(piano_distribution[emotion, ]) > 0) {
      next
    }
    
    # Find best match for this emotion (either category)
    best_candidate <- matches %>%
      filter(!is.na(piano_check), piano_check == 1, 
             max_emotion == emotion,
             !(Number_S1 %in% instruments_stimuli)) %>%
      arrange(distance) %>%
      head(1)
    
    if (nrow(best_candidate) > 0) {
      # Add to selection
      piano_stimuli <- c(piano_stimuli, best_candidate$Number_S1)
      
      # Update distribution
      category <- best_candidate$category
      piano_distribution[emotion, category] <- piano_distribution[emotion, category] + 1
    }
  }
  
  # Second pass: fill up to 10 total
  remaining_slots <- 10 - length(piano_stimuli)
  if (remaining_slots > 0) {
    piano_candidates <- matches %>%
      filter(!is.na(piano_check), piano_check == 1,
             !(Number_S1 %in% instruments_stimuli),
             !(Number_S1 %in% piano_stimuli)) %>%
      arrange(distance)
    
    # Process each candidate
    for (i in 1:nrow(piano_candidates)) {
      if (length(piano_stimuli) >= 10) break
      
      candidate <- piano_candidates[i, ]
      emotion <- candidate$max_emotion
      category <- candidate$category
      
      # Check if we've reached the maximum for this emotion-category
      if (piano_distribution[emotion, category] < max_per_emotion_category) {
        # Add to selection
        piano_stimuli <- c(piano_stimuli, candidate$Number_S1)
        
        # Update distribution
        piano_distribution[emotion, category] <- piano_distribution[emotion, category] + 1
      }
    }
  }
  
  # Print summary
  print("=== INITIAL SELECTION SUMMARY ===")
  print(paste("Instruments stimuli (instruments=0):", length(instruments_stimuli)))
  print(paste("Piano stimuli (piano=1):", length(piano_stimuli)))
  
  print("Instruments distribution:")
  print(instruments_distribution)
  
  print("Piano distribution:")
  print(piano_distribution)
  
  # Create combined distribution
  combined_distribution <- piano_distribution + instruments_distribution
  print("Combined distribution:")
  print(combined_distribution)
  
  # Get detailed information about selected stimuli
  instruments_df <- matches %>%
    filter(Number_S1 %in% instruments_stimuli) %>%
    select(Number_S1, max_emotion, category, distance, piano_check, instruments_check)
  
  piano_df <- matches %>%
    filter(Number_S1 %in% piano_stimuli) %>%
    select(Number_S1, max_emotion, category, distance, piano_check, instruments_check)
  
  # Return the results
  result <- list(
    piano_stimuli = piano_stimuli,
    instruments_stimuli = instruments_stimuli,
    piano_distribution = piano_distribution,
    instruments_distribution = instruments_distribution,
    combined_distribution = combined_distribution,
    piano_df = piano_df,
    instruments_df = instruments_df
  )
  
  return(result)
}

# Function 2: Manual fill in the gaps with precise counts since counting loop didn't work
fill_gaps <- function(matches, initial_selection) {
  # Start with the initial selection
  piano_df <- matches %>%
    filter(Number_S1 %in% initial_selection$piano_stimuli) %>%
    mutate(rating_task = "piano")
  
  instruments_df <- matches %>%
    filter(Number_S1 %in% initial_selection$instruments_stimuli) %>%
    mutate(rating_task = "instruments")
  
  # Combine initial selection
  final_selection <- rbind(piano_df, instruments_df)
  
  # Get IDs of stimuli already selected
  used_ids <- final_selection$Number_S1
  
  # --- HAPPY ---
  # We have: 3 piano (2 high, 1 moderate), 1 instruments (0 high, 1 moderate)
  # Need: 1 piano=0 for moderate, 3 instruments=1 (2 high, 1 moderate)
  
  # Add 1 piano=0 for moderate
  candidates <- matches %>%
    filter(max_emotion == "happy",
           category == "moderate",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 2 instruments=1 for high
  candidates <- matches %>%
    filter(max_emotion == "happy",
           category == "high",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(2)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 1 instruments=1 for moderate
  candidates <- matches %>%
    filter(max_emotion == "happy",
           category == "moderate",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # --- SAD ---
  # We have: 2 piano (1 high, 1 moderate), 2 instruments (1 high, 1 moderate)
  # Need: 2 piano=0 (1 high, 1 moderate), 2 instruments=1 (1 high, 1 moderate)
  
  # Add 1 piano=0 for high
  candidates <- matches %>%
    filter(max_emotion == "sad",
           category == "high",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 1 piano=0 for moderate
  candidates <- matches %>%
    filter(max_emotion == "sad",
           category == "moderate",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 1 instruments=1 for high
  candidates <- matches %>%
    filter(max_emotion == "sad",
           category == "high",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 1 instruments=1 for moderate
  candidates <- matches %>%
    filter(max_emotion == "sad",
           category == "moderate",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # --- TENDER ---
  # We have: 1 piano (0 high, 1 moderate), 2 instruments (0 high, 2 moderate)
  # Need: 3 piano=0 (2 high, 1 moderate), 2 instruments=1 (2 high, 0 moderate)
  
  # Add 2 piano=0 for high
  candidates <- matches %>%
    filter(max_emotion == "tender",
           category == "high",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(2)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 1 piano=0 for moderate
  candidates <- matches %>%
    filter(max_emotion == "tender",
           category == "moderate",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 2 instruments=1 for high
  candidates <- matches %>%
    filter(max_emotion == "tender",
           category == "high",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(2)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # --- FEAR ---
  # We have: 1 piano (1 high, 0 moderate), 4 instruments (2 high, 2 moderate)
  # Need: 3 piano=0 (1 high, 2 moderate), 0 instruments
  
  # Add 1 piano=0 for high
  candidates <- matches %>%
    filter(max_emotion == "fear",
           category == "high",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 2 piano=0 for moderate
  candidates <- matches %>%
    filter(max_emotion == "fear",
           category == "moderate",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(2)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # --- NEUTRAL ---
  # We have: 3 piano (2 high, 1 moderate), 1 instruments (1 high, 0 moderate)
  # Need: 1 piano=0 for moderate, 3 instruments=1 (1 high, 2 moderate)
  
  # Add 1 piano=0 for moderate
  candidates <- matches %>%
    filter(max_emotion == "neutral",
           category == "moderate",
           piano_check == 0,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "piano"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 1 instruments=1 for high
  candidates <- matches %>%
    filter(max_emotion == "neutral",
           category == "high",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(1)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Add 2 instruments=1 for moderate
  candidates <- matches %>%
    filter(max_emotion == "neutral",
           category == "moderate",
           instruments_check == 1,
           !(Number_S1 %in% used_ids)) %>%
    arrange(distance) %>%
    head(2)
  
  if (nrow(candidates) > 0) {
    candidates$rating_task <- "instruments"
    final_selection <- rbind(final_selection, candidates)
    used_ids <- c(used_ids, candidates$Number_S1)
  }
  
  # Print summary
  cat("=== FINAL SELECTION SUMMARY ===\n")
  
  # Count by task
  piano_count <- sum(final_selection$rating_task == "piano")
  instruments_count <- sum(final_selection$rating_task == "instruments")
  cat("Piano task:", piano_count, "/ Instruments task:", instruments_count, "\n")
  
  # Count by check values
  piano_0_count <- sum(final_selection$rating_task == "piano" & final_selection$piano_check == 0, na.rm = TRUE)
  piano_1_count <- sum(final_selection$rating_task == "piano" & final_selection$piano_check == 1, na.rm = TRUE)
  instruments_0_count <- sum(final_selection$rating_task == "instruments" & final_selection$instruments_check == 0, na.rm = TRUE)
  instruments_1_count <- sum(final_selection$rating_task == "instruments" & final_selection$instruments_check == 1, na.rm = TRUE)
  
  cat("Piano values (0/1):", piano_0_count, "/", piano_1_count, "\n")
  cat("Instruments values (0/1):", instruments_0_count, "/", instruments_1_count, "\n")
  
  # Emotion counts
  emotion_counts <- table(final_selection$max_emotion)
  cat("Stimuli per emotion:", paste(names(emotion_counts), emotion_counts, sep="=", collapse=", "), "\n")
  
  # Emotion-Category distribution
  cat("Emotion-Category distribution:\n")
  print(table(final_selection$max_emotion, final_selection$category))
  
  # Task distributions
  cat("Piano task distribution:\n")
  print(table(final_selection$max_emotion[final_selection$rating_task == "piano"], 
              final_selection$category[final_selection$rating_task == "piano"]))
  
  cat("Instruments task distribution:\n")
  print(table(final_selection$max_emotion[final_selection$rating_task == "instruments"], 
              final_selection$category[final_selection$rating_task == "instruments"]))
  
  return(final_selection)
}

# Function to compare originally selected stimuli to imp set
compare_selections <- function(final_selection, selected) {
  # Define variables to compare (base names only)
  base_variables <- c("valence", "energy", "centrality", "happy", "sad", "tender", "fear")
  
  # Create a data frame to store comparison results
  results <- data.frame(
    variable = character(),
    t_statistic = numeric(),
    t_p_value = numeric(),
    w_statistic = numeric(),
    w_p_value = numeric(),
    cohens_d = numeric(),
    mean_diff = numeric(),
    selected_S2_mean = numeric(),
    imp_set_S1_mean = numeric(), 
    selected_S2_sd = numeric(),
    imp_set_S1_sd = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Compare each variable
  for (var in base_variables) {
    # Get values from S2 columns in final_selection
    selected_S2_values <- final_selection[[paste0("S2_", var)]]
    
    # Get values from S1 columns in final_selection
    imp_set_S1_values <- final_selection[[paste0("S1_", var)]]
    
    # Calculate basic statistics
    selected_S2_mean <- mean(selected_S2_values, na.rm = TRUE)
    imp_set_S1_mean <- mean(imp_set_S1_values, na.rm = TRUE)
    selected_S2_sd <- sd(selected_S2_values, na.rm = TRUE)
    imp_set_S1_sd <- sd(imp_set_S1_values, na.rm = TRUE)
    mean_diff <- selected_S2_mean - imp_set_S1_mean
    
    # Perform t-test
    t_test <- tryCatch({
      t.test(selected_S2_values, imp_set_S1_values)
    }, error = function(e) {
      return(list(statistic = NA, p.value = NA))
    })
    
    # Perform Wilcoxon test
    w_test <- tryCatch({
      wilcox.test(selected_S2_values, imp_set_S1_values)
    }, error = function(e) {
      return(list(statistic = NA, p.value = NA))
    })
    
    # Calculate Cohen's d
    pooled_sd <- sqrt(((length(selected_S2_values) - 1) * selected_S2_sd^2 + 
                         (length(imp_set_S1_values) - 1) * imp_set_S1_sd^2) / 
                        (length(selected_S2_values) + length(imp_set_S1_values) - 2))
    
    cohens_d <- mean_diff / pooled_sd
    
    # Add results to the data frame
    results <- rbind(results, data.frame(
      variable = var,
      t_statistic = unname(t_test$statistic),
      t_p_value = t_test$p.value,
      w_statistic = unname(w_test$statistic),
      w_p_value = w_test$p.value,
      cohens_d = cohens_d,
      mean_diff = mean_diff,
      selected_S2_mean = selected_S2_mean, 
      imp_set_S1_mean = imp_set_S1_mean,
      selected_S2_sd = selected_S2_sd,
      imp_set_S1_sd = imp_set_S1_sd
    ))
  }
  
  # Return the results data frame
  return(results)
}

# Function to visualize imp set and the original selection
create_va_plot <- function(final_selection, selected) {
  # Use ggplot2 with a consistent color scheme
  emotion_colors <- c(
    "happy" = "#FFA500",   # Orange
    "sad" = "#0066CC",     # Blue
    "fear" = "#800080",    # Purple
    "tender" = "#4CAF50",  # Green
    "neutral" = "#404040"  # Darker grey
  )
  
  # Prepare data for plotting
  plot_data <- final_selection %>%
    select(max_emotion, category, S1_valence, S1_energy, rating_task) %>%
    rename(valence = S1_valence, energy = S1_energy) %>%
    mutate(
      dataset = "Imp_set",
      category = factor(category, levels = c("moderate", "high"))
    )
  
  # Create the plot for imp_set stimuli
  p <- ggplot(plot_data, aes(x = valence, y = energy)) +
    # Add reference lines
    geom_vline(xintercept = 5, linetype = "dashed", alpha = 0.3) +
    geom_hline(yintercept = 5, linetype = "dashed", alpha = 0.3) +
    # Plot the stimuli
    geom_point(aes(color = max_emotion, 
                   shape = rating_task,
                   size = category)) +
    # Set scales and labels
    scale_color_manual(values = emotion_colors,
                       name = "Emotion Category",
                       labels = c("Fear", "Happy", "Neutral", "Sad", "Tender")) +
    scale_shape_manual(values = c("piano" = 17, "instruments" = 19),
                       name = "Rating Task") +
    scale_size_manual(values = c("moderate" = 3, "high" = 4.5),
                      name = "Category") +
    scale_x_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
    scale_y_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
    labs(x = "Valence", 
         y = "Arousal",
         title = "Imp_set Stimuli in the Valence-Arousal Space") +
    theme_minimal() +
    theme(
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
  
  # Save the plot
  ggsave("imp_set_valence_arousal.png", p, width = 8, height = 6, dpi = 300, bg = "white")
  
  # Create a comparison plot
  # Prepare S2 data
  selected_plot_data <- final_selection %>%
    select(max_emotion, category, S2_valence, S2_energy) %>%
    rename(valence = S2_valence, energy = S2_energy) %>%
    mutate(dataset = "Original")
  
  # Combine data
  combined_plot_data <- bind_rows(selected_plot_data, plot_data) %>%
    mutate(dataset = factor(dataset, levels = c("Original", "Imp_set")))
  
  # Create comparative plot
  p_compare <- ggplot(combined_plot_data, aes(x = valence, y = energy)) +
    # Add reference lines
    geom_vline(xintercept = 5, linetype = "dashed", alpha = 0.3) +
    geom_hline(yintercept = 5, linetype = "dashed", alpha = 0.3) +
    # Plot the stimuli
    geom_point(aes(color = max_emotion, 
                   shape = dataset,
                   alpha = dataset)) +
    # Set scales and labels
    scale_color_manual(values = emotion_colors,
                       name = "Emotion Category") +
    scale_shape_manual(values = c("Original" = 1, "Imp_set" = 19),
                       name = "Dataset") +
    scale_alpha_manual(values = c("Original" = 0.4, "Imp_set" = 1),
                       name = "Dataset") +
    scale_x_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
    scale_y_continuous(limits = c(1, 9), breaks = seq(1, 9, 1)) +
    labs(x = "Valence", 
         y = "Arousal",
         title = "Comparison of Original Selection and Imp_set") +
    theme_minimal() +
    theme(
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
  
  # Save the comparative plot
  ggsave("comparison_valence_arousal.png", p_compare, width = 8, height = 6, dpi = 300, bg = "white")
  
  # Return both plots
  return(list(imp_set_plot = p, comparison_plot = p_compare))
}


# RUN IT
# 1. Load and preprocess data:
data <- read_and_preprocess(normalize=TRUE)

# 2. Find matches without duplicates:
matches <- find_matches(data$selected, data$imp_set)
View(matches)

# 3. Select initial stimuli (piano=1 and instruments=0):
initial_selection <- select_initial_stimuli(matches)

# 4. Fill in the gaps using results of the initial selection process:
final_selection <- fill_gaps(matches, initial_selection)
View(final_selection)

# 6. Run statistical comparison:
comparison_results <- compare_selections(final_selection, data$selected)
View(comparison_results)

# 7. Visualize it:
plots <- create_va_plot(final_selection, data$selected)
plots$imp_set_plot
plots$comparison_plot
