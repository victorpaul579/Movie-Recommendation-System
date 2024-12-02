Movie Recommendation System

Project Overview

The goal of this project is to analyze people's movie preferences by studying their viewing and rating history. Using Association Rule Mining, this system identifies patterns and determines which movies or genres are commonly watched together. By the end of this project, you will gain insights into how a basic recommendation system works.

Features

•	Analyze movie viewing and rating history.

•	Identify associations between movies and genres.

•	Predict a list of recommended movies based on user-selected inputs.

•	Interactive UI built with Streamlit.

Getting Started

Prerequisites

To test the code, ensure you have the following:


1.	Python installed on your system.

2.	Required libraries from requirements.txt installed.

3.	Datasets:

o	movies.csv

o	ratings.csv

Setup Instructions

1.	Clone the repository:

git clone https://github.com/victorpaul579/Movie-Recommendation-System.git

2.	Navigate to the project directory:

cd Movie-Recommendation-System

3.	Install dependencies:

pip install -r requirements.txt

4.	Place the required datasets (movies.csv, ratings.csv) in the project directory.

Running the Application

Run the following command to launch the interactive UI:

streamlit run app.py

How to Use

1.	Open the application in your web browser (Streamlit will provide a link).

2.	Select three movies from the dropdown menu.

3.	Click the Predict button to generate the top 10 recommended movies based on your choices.

________________________________________

Project Objective

•	Use Association Rule Mining to identify patterns in movie-watching habits.

•	Build a system that predicts movie recommendations based on user inputs.

Dataset

•	movies.csv: Contains information about movies, such as titles and genres.

•	ratings.csv: Contains user ratings for various movies.

Technologies Used

•	Python for backend development.

•	Streamlit for building the interactive UI.

•	Pandas for data manipulation.

•	Scikit-learn for preprocessing and model implementation.

