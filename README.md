Movie Recommendation System
Project Overview
The Movie Recommendation System aims to analyze people's movie preferences by studying their viewing and rating history. Using Association Rule Mining, this system identifies patterns and determines which movies or genres are commonly watched together. By the end of this project, you will gain insights into how basic recommendation systems work.

Features
Analyze movie viewing and rating history.
Identify associations between movies and genres.
Predict a list of recommended movies based on user-selected inputs.
Interactive UI built with Streamlit for ease of use.
Getting Started
Prerequisites
To test the code, ensure you have the following:

Python installed on your system.
Required libraries installed from the requirements.txt file.
Datasets: movies.csv and ratings.csv.
Setup Instructions
Clone the repository:

bash
Copy code
git clone https://github.com/victorpaul579/Movie-Recommendation-System.git
Navigate to the project directory:

bash
Copy code
cd Movie-Recommendation-System
Install dependencies:

bash
Copy code
pip install -r requirements.txt
Place the required datasets (movies.csv and ratings.csv) in the project directory.

Run the application:

bash
Copy code
streamlit run app.py
How to Use
Open the application in your web browser (Streamlit will provide a link).
Select up to three movies from the dropdown menu.
Click the Predict button to generate the top 10 recommended movies based on your choices.
Project Objective
Use Association Rule Mining to identify patterns in movie-watching habits.
Build a system that predicts movie recommendations based on user inputs.
Dataset Details
movies.csv: Contains information about movies, such as titles and genres.
ratings.csv: Contains user ratings for various movies.
Technologies Used
Python for backend development.
Streamlit for building the interactive UI.
Pandas for data manipulation.
Scikit-learn for preprocessing and model implementation.
