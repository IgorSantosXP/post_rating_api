# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Posts API', type: :request do
  describe 'POST /posts' do
    context 'with valid params' do
      it 'create a new post and a new user' do
        params = {
          login: 'user_login',
          post: {
            title: 'My first post',
            body: 'This is the post content!',
            ip: '127.0.0.1'
          }
        }

        post '/posts', params: params
        expect(response).to have_http_status(:created)
        expect(Post.count).to eq(1)
        expect(User.count).to eq(1)
      end
    end
  end
end
