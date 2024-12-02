# R script for movie recommendations

# Install and load necessary libraries
if (!require("dplyr")) install.packages("dplyr")
if (!require("data.table")) install.packages("data.table")
if (!require("reshape2")) install.packages("reshape2")
library(dplyr)
library(data.table)
library(reshape2)

# Load data
movies <- fread("movie.csv", col.names = c("movieId", "title", "genres"))
ratings <- fread("rating.csv", col.names = c("userId", "movieId", "rating", "timestamp"))

# Randomly select 1000 unique users
set.seed(123)  # Ensure reproducibility
selected_users <- sample(unique(ratings$userId), 1000)

# Filter ratings to include only selected users
filtered_ratings <- ratings %>%
  filter(userId %in% selected_users) %>%
  select(-timestamp)  # Drop the 'timestamp' column

# Merge movies and ratings
movie_ratings <- merge(movies, filtered_ratings, by = "movieId")

# Create a user-item rating matrix
user_rating_matrix <- dcast(
  movie_ratings, 
  userId ~ title, 
  value.var = "rating", 
  fun.aggregate = sum
)

# Similarity computation function
compute_similarity <- function(userInput, user_rating) {
  # Validate if the userInput movies exist in the dataset
  valid_movies <- userInput[userInput %in% colnames(user_rating)]
  
  if (length(valid_movies) == 0) 
    stop("None of the specified movies are present in the dataset.")
  
  # Compute Pearson similarity scores
  similarity <- rowSums(sapply(valid_movies, function(movie) {
    sapply(user_rating, function(column) {
      cor(column, user_rating[[movie]], method = "pearson", use = "pairwise.complete.obs")
    })
  }))
  
  return(similarity)
}

# Recommendation generation function
generate_recommendations <- function(userInput) {
  # Compute similarity
  similarity <- compute_similarity(userInput, user_rating_matrix)
  
  # Create dataframe with similarity scores and merge with movie metadata
  correlatedMovies <- data.frame(
    title = names(similarity),
    correlation = similarity,
    row.names = NULL
  )
  reviews <- movie_ratings %>%
    group_by(title) %>%
    summarize(count = n(), mean = round(mean(rating), 1))
  correlatedMovies <- merge(correlatedMovies, reviews, by = "title", all.x = TRUE)
  correlatedMovies <- merge(correlatedMovies, movies, by = "title", all.x = TRUE)
  
  # Filter and sort recommendations
  recommendations <- correlatedMovies %>%
    filter(mean > 3.5 & count > 300 & !(title %in% userInput)) %>%
    arrange(desc(correlation)) %>%
    head(10)
  
  return(recommendations)
}

# Sample User Input Movies
sample_movies <- c("The Matrix (1999)", "Titanic (1997)", "Avatar (2009)")

# Print the sample input movies
cat("Sample Input Movies:\n")
print(sample_movies)

# Generate recommendations using the `generate_recommendations` function
tryCatch({
  # Call the recommendation function with the sample input
  recommendations <- generate_recommendations(sample_movies)
  
  # Display the top 10 recommended movies
  cat("\nTop 10 Recommended Movies:\n")
  print(head(recommendations$title, 10))
  
}, error = function(e) {
  # Handle any errors gracefully
  cat("Error while generating recommendations:", e$message, "\n")
})


# Load required libraries
# -------------------------------------------------
# Ensure that the `readxl` package is installed and loaded for reading Excel files.
if (!require("readxl")) install.packages("readxl")
library(readxl)

# Step 1: Read x_data and y_data files
# -------------------------------------------------
# Read the Excel files `x_data` and `y_data` which contain the watched movies
# and future movies data, respectively. Replace the file paths with actual paths if needed.
x_data_file <- "x_data.xlsx"  # Path to x_data file
y_data_file <- "y_data.xlsx"  # Path to y_data file

# Read the data into dataframes
x_data <- read_excel(x_data_file, col_names = FALSE)
y_data <- read_excel(y_data_file, col_names = FALSE)

# Step 2: Parse the rows into individual movie lists for both x_data and y_data
# -------------------------------------------------
# Define a helper function to parse movie lists from each row in the datasets.
parse_movies <- function(row) {
  # Remove leading/trailing brackets
  movies <- gsub("^\\(|\\)$", "", row)
  # Split the string by ", and optional spaces, then return as a list of movies
  movie_list <- strsplit(movies, "\",\\s*\"")[[1]]
  # Remove any remaining quotes from each movie title
  return(gsub("\"", "", movie_list))
}

# Apply the `parse_movies` function to each row in x_data and y_data
x_data$parsed_movies <- lapply(x_data$`...1`, parse_movies)
y_data$parsed_movies <- lapply(y_data$`...1`, parse_movies)

# Step 3: Generate recommendations for the first 3 rows
# -------------------------------------------------
# Function: generate_recommendations_for_users
# Purpose: Generate movie recommendations for a specified number of users (rows)
# Input:
# - parsed_movies: A list of movie lists for each user (e.g., from x_data).
# - recommendation_function: The function used to generate recommendations (e.g., `generate_recommendations`).
# Output:
# - A list of recommendations for each user.
generate_recommendations_for_users <- function(parsed_movies, recommendation_function) {
  recommendations_list <- list()  # Initialize an empty list to store recommendations
  
  # Loop over the first 3 users or the available rows (whichever is smaller)
  for (i in 1:min(3, length(parsed_movies))) {
    tryCatch({
      # Get the watched movies for the current user
      userInput <- parsed_movies[[i]]
      # Generate recommendations using the recommendation function
      recommendations <- recommendation_function(userInput)
      # Extract the top 10 recommended movie titles
      recommended_titles <- head(recommendations$title, 10)
      # Store the recommendations in the list
      recommendations_list[[i]] <- recommended_titles
    }, error = function(e) {
      # Handle errors by setting the current user's recommendations to NA
      recommendations_list[[i]] <- NA
      # Print an error message for the user
      cat(sprintf("Error for User %d: %s\n", i, e$message))
    })
  }
  
  return(recommendations_list)  # Return the list of recommendations
}

# Generate recommendations for the first 3 users in x_data
recommendations <- generate_recommendations_for_users(x_data$parsed_movies, generate_recommendations)

# Step 4: Combine x_data, y_data, and recommendations into one dataframe
# -------------------------------------------------
# Create a dataframe that combines:
# - Watched movies (from x_data)
# - Recommended movies (from the recommendation function)
# - Future movies (from y_data)
df <- data.frame(
  watched_movies = I(x_data$parsed_movies[1:3]),         # Preserve list structure using `I()`
  recommended_movies = I(recommendations),              # Preserve list structure using `I()`
  future_movies = I(y_data$parsed_movies[1:3])          # Preserve list structure using `I()`
)

# Step 5: Calculate the number of matches between recommended and future movies
# -------------------------------------------------
# Add a new column to the dataframe that calculates the number of movies
# in the recommended list that are also present in the future movies list for each user.
df$num_matches <- sapply(1:nrow(df), function(i) {
  rec <- df$recommended_movies[[i]]  # Get recommended movies for the user
  future <- df$future_movies[[i]]    # Get future movies for the user
  if (!is.null(rec) && !is.null(future)) {
    # Count the number of matches between the two lists
    return(sum(rec %in% future))
  } else {
    return(0)  # Return 0 if either list is NULL
  }
})

# Step 6: Print the final dataframe
# -------------------------------------------------
# Display the combined dataframe, including the number of matches for each user.
print(df)

# Display the number of matches for each row in a readable format
cat("\nNumber of Matches Between Recommended and Future Movies:\n")
print(df$num_matches)

# Metrics Calculation for Movie Recommendations

# Function to calculate evaluation metrics
calculate_metrics <- function(df) {
  # Validate if `num_matches` column exists
  if (!"num_matches" %in% colnames(df)) {
    stop("The dataframe does not contain the 'num_matches' column.")
  }
  
  # Total number of recommendations per user
  total_recommendations <- 10
  
  # Mean Absolute Error (MAE)
  # MAE measures how far the number of matches is from the maximum possible matches (10)
  mae <- mean(abs(df$num_matches - total_recommendations))
  
  # Accuracy
  # Accuracy is the ratio of matched movies to total recommendations
  accuracy <- mean(df$num_matches / total_recommendations)
  
  # Precision
  # Precision measures the proportion of correctly recommended movies out of the total recommendations
  precision <- sum(df$num_matches) / (nrow(df) * total_recommendations)
  
  # Return the metrics as a list
  metrics <- list(
    Mean_Absolute_Error = round(mae, 2),
    Accuracy = round(accuracy * 100, 2),  # Convert to percentage
    Precision = round(precision * 100, 2) # Convert to percentage
  )
  
  return(metrics)
}

# Example usage
metrics <- calculate_metrics(df)

# Print the metrics
cat("Evaluation Metrics for Movie Recommendations:\n")
print(metrics)

# Additional insights
cat("\nDetailed Analysis:\n")
cat(sprintf("Total Users Evaluated: %d\n", nrow(df)))
cat(sprintf("Total Recommendations Made: %d\n", nrow(df) * 10))
cat(sprintf("Total Matches Found: %d\n", sum(df$num_matches)))
cat(sprintf("Mean Matches Per User: %.2f\n", mean(df$num_matches)))
