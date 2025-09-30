# frozen_string_literal: true

class PostsController < ApplicationController
  def create
    user = User.find_or_create_by(login: params[:login])
    post = user.posts.new(post_params)

    if post.save
      render json: post, include: :user, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :ip)
  end
end
