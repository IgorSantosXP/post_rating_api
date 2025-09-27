# frozen_string_literal: true

class PostsController < ApplicationController
  def create
    user = User.find_or_create_by(login: params[:login])
    post = user.posts.new(post_params)

    if post.save
      render json: post, status: :created
    else
      render json: { errors: post.errors }, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.expect(post: %i[title body ip])
  end
end
