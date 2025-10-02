# Post Rating API

This is a RESTful API built with Ruby on Rails. The application allows users to create posts, rate those posts, and query for statistics such as top-rated posts and IP addresses shared by multiple authors.

## Tech Stack

* **Ruby**: 3.3.5
* **Ruby on Rails**: 8.0.3 (API-only)
* **Database**: PostgreSQL (version 14 or higher is recommended)
* **Testing**: RSpec
* **Linting**: RuboCop

## Setup and Installation

    git clone https://github.com/IgorSantosXP/post_rating_api.git
    cd post_rating_api
    bundle install

    
    # Configure the database
    rails db:create
    rails db:migrate
    rails db:seed

## Notes on Seeding

- The seeds create 200,000 posts and about 75% of them get ratings.
- This process may take several minutes to complete.
- It uses Typhoeus to make concurrent HTTP requests to the API.

## How to Run the Test Suite

To execute the automated test suite with RSpec, run the following command:

    bundle exec rspec

## Linting

To check the code style with RuboCop:

    bundle exec rubocop

## Endpoints

    POST /posts
      - Params: login, post[title], post[body], post[ip]
    
    POST /posts/:post_id/ratings
      - Params: rating[user_id], rating[value]
    
    GET /posts/top?count=10
      - Returns the highest rated posts
    
    GET /posts/shared_ips
      - Returns IPs shared between users

