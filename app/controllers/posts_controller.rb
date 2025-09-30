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

  def top
    count = params[:count].to_i
    top_posts = Post
                .select(:id, :title, :body)
                .joins(:ratings)
                .group('posts.id')
                .order('AVG(ratings.value) DESC')
                .limit(count)

    render json: top_posts, status: :ok
  end

  def shared_ips
    shared_ips_data = Post
                      .select('posts.ip, ARRAY_AGG(DISTINCT users.login) as logins')
                      .joins(:user)
                      .group('posts.ip')
                      .having('COUNT(DISTINCT users.id) > 1')

    render json: shared_ips_data.as_json(except: :id), status: :ok
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :ip)
  end
end
