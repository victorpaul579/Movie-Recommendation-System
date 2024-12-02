import streamlit as st
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class MovieRecommender:
    def __init__(self, movies_path, ratings_path):
        """
        Initialize the movie recommender with robust data loading
        
        Args:
            movies_path (str): Path to movies CSV
            ratings_path (str): Path to ratings CSV
        """
        # Load movies and ratings with explicit type handling
        self.movies = self._load_movies(movies_path)
        self.ratings = self._load_ratings(ratings_path)
        
        # Preprocess data
        self._preprocess_data()
    
    def _load_movies(self, movies_path):
        """
        Load and clean movies dataset
        
        Args:
            movies_path (str): Path to movies CSV
        
        Returns:
            pd.DataFrame: Cleaned movies dataframe
        """
        try:
            # Try loading with different column configurations
            try:
                # First try with existing column names
                movies = pd.read_csv(movies_path)
            except Exception:
                # If that fails, use generic column names
                movies = pd.read_csv(movies_path, header=None, names=['movieId', 'title', 'genres'])
            
            # Ensure required columns exist
            required_columns = ['movieId', 'title', 'genres']
            for col in required_columns:
                if col not in movies.columns:
                    raise ValueError(f"Missing required column: {col}")
            
            # Clean and validate data
            movies['movieId'] = pd.to_numeric(movies['movieId'], errors='coerce')
            movies['title'] = movies['title'].astype(str)
            movies['genres'] = movies['genres'].fillna('Unknown')
            
            # Drop rows with invalid movieId
            movies = movies.dropna(subset=['movieId'])
            
            return movies
        
        except Exception as e:
            st.error(f"Error loading movies data: {e}")
            raise
    
    def _load_ratings(self, ratings_path):
        """
        Load and clean ratings dataset
        
        Args:
            ratings_path (str): Path to ratings CSV
        
        Returns:
            pd.DataFrame: Cleaned ratings dataframe
        """
        try:
            # Try loading with different column configurations
            try:
                # First try with existing column names
                ratings = pd.read_csv(ratings_path)
            except Exception:
                # If that fails, use generic column names
                ratings = pd.read_csv(ratings_path, header=None, names=['userId', 'movieId', 'rating', 'timestamp'])
            
            # Ensure required columns exist
            required_columns = ['userId', 'movieId', 'rating']
            for col in required_columns:
                if col not in ratings.columns:
                    raise ValueError(f"Missing required column: {col}")
            
            # Convert columns to appropriate types
            ratings['userId'] = pd.to_numeric(ratings['userId'], errors='coerce')
            ratings['movieId'] = pd.to_numeric(ratings['movieId'], errors='coerce')
            ratings['rating'] = pd.to_numeric(ratings['rating'], errors='coerce')
            
            # Drop rows with invalid data
            ratings = ratings.dropna(subset=['userId', 'movieId', 'rating'])
            
            return ratings
        
        except Exception as e:
            st.error(f"Error loading ratings data: {e}")
            raise
    
    def _preprocess_data(self):
        """
        Preprocess movie and rating data
        """
        # Merge movies and ratings
        self.movie_ratings = pd.merge(self.movies, self.ratings, on='movieId')
        
        # Compute average ratings and count with numeric aggregation
        self.movie_stats = self.movie_ratings.groupby('title').agg({
            'rating': ['mean', 'count']
        }).reset_index()
        
        # Flatten multi-level column names
        self.movie_stats.columns = ['title', 'mean_rating', 'rating_count']
        
        # Ensure numeric types
        self.movie_stats['mean_rating'] = pd.to_numeric(self.movie_stats['mean_rating'], errors='coerce')
        self.movie_stats['rating_count'] = pd.to_numeric(self.movie_stats['rating_count'], errors='coerce')
        
        # Create content-based feature matrix
        self.tfidf = TfidfVectorizer(stop_words='english')
        self.genre_matrix = self.tfidf.fit_transform(self.movies['genres'].fillna('Unknown'))
    
    def get_recommendations(self, input_movies, top_n=10):
        """
        Generate movie recommendations
        
        Args:
            input_movies (list): List of movies user likes
            top_n (int): Number of recommendations to return
        
        Returns:
            pd.DataFrame: Recommended movies
        """
        # Validate input movies
        valid_movies = [movie for movie in input_movies if movie in self.movies['title'].values]
        
        if not valid_movies:
            raise ValueError("None of the specified movies are in the dataset")
        
        # Compute genre similarity for input movies
        input_genre_vectors = self.tfidf.transform(
            self.movies[self.movies['title'].isin(valid_movies)]['genres'].fillna('Unknown')
        )
        
        # Compute cosine similarity with all movies
        genre_similarities = cosine_similarity(input_genre_vectors, self.genre_matrix)[0]
        
        # Create recommendation dataframe
        recommendations = pd.DataFrame({
            'title': self.movies['title'],
            'genres': self.movies['genres'],
            'genre_similarity': genre_similarities
        })
        
        # Merge with movie stats
        recommendations = recommendations.merge(
            self.movie_stats, 
            on='title', 
            how='left'
        )
        
        # Filter recommendations
        filtered_recommendations = recommendations[
            # Exclude input movies
            ~recommendations['title'].isin(valid_movies) & 
            # Filter by rating and count
            (recommendations['mean_rating'] > 3.5) & 
            (recommendations['rating_count'] > 300)
        ]
        
        # Sort and return top recommendations
        return (filtered_recommendations
            .sort_values('genre_similarity', ascending=False)
            .head(top_n)
            [['title', 'genres', 'genre_similarity', 'mean_rating', 'rating_count']]
            .rename(columns={
                'genre_similarity': 'similarity', 
                'mean_rating': 'mean',
                'rating_count': 'count'
            })
        )

def main():
    # Page configuration
    st.set_page_config(page_title="Movie Recommender", page_icon="🎬")
    
    # Title
    st.title('🎬 Movie Recommender System')
    
    # Initialize recommender with error handling
    try:
        recommender = MovieRecommender('movie.csv', 'rating.csv')
    except Exception as e:
        st.error(f"Fatal error initializing recommender: {e}")
        st.stop()
    
    # Load movie titles
    movie_titles = sorted(recommender.movies['title'].unique())
    
    # Movie selection
    st.subheader('Select Movies You Like')
    selected_movies = st.multiselect(
        'Choose up to 3 movies', 
        movie_titles, 
        max_selections=3
    )
    
    # Recommendation generation
    if st.button('Get Recommendations'):
        if len(selected_movies) == 0:
            st.warning('Please select at least one movie')
        else:
            with st.spinner('Generating recommendations...'):
                try:
                    recommendations = recommender.get_recommendations(selected_movies)
                    
                    if not recommendations.empty:
                        st.subheader('Recommended Movies')
                        
                        # Display recommendations
                        st.dataframe(
                            recommendations,
                            column_config={
                                "title": "Movie",
                                "genres": "Genres",
                                "similarity": "Genre Similarity",
                                "mean": "Avg Rating",
                                "count": "Rating Count"
                            },
                            hide_index=True,
                            use_container_width=True
                        )
                    else:
                        st.warning('No recommendations found')
                
                except Exception as e:
                    st.error(f"Error generating recommendations: {e}")

if __name__ == '__main__':
    main()