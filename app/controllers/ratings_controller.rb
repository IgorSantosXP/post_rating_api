# frozen_string_literal: true

class RatingsController < ApplicationController
  before_action :set_post

  def create
    rating = @post.ratings.new(rating_params)

    if rating.save
      new_average = @post.ratings.average(:value).to_f.round(2)
      render json: { average_rating: new_average }, status: :created
    else
      render json: { errors: rating.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def rating_params
    params.permit(:user_id, :value)
  end
end
