# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Posts API', type: :request do
  describe 'POST /posts' do
    context 'when the parameters are valid and the user does not exist' do
      let(:valid_params) do
        {
          login: 'new_user',
          post: { title: 'My first post', body: 'This is the post content!', ip: '127.0.0.1' }
        }
      end

      it 'create a new user' do
        expect { post '/posts', params: valid_params }
          .to change(User, :count).by(1)
      end

      it 'create a new post' do
        expect { post '/posts', params: valid_params }
          .to change(Post, :count).by(1)
      end

      it "returns the created post with the user's attributes" do
        post '/posts', params: valid_params

        expect(response).to have_http_status(:created)

        json_response = response.parsed_body
        expect(json_response['title']).to eq('My first post')
        expect(json_response['user']['login']).to eq('new_user')
      end
    end

    context 'when the parameters are valid and the user exists' do
      before { User.create!(login: 'existing_user') }

      let(:valid_params) do
        {
          login: 'existing_user',
          post: { title: 'Another post', body: 'More content', ip: '192.168.1.1' }
        }
      end

      it 'does not create a new user' do
        expect { post '/posts', params: valid_params }
          .not_to change(User, :count)
      end

      it 'create a new post' do
        expect { post '/posts', params: valid_params }
          .to change(Post, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          login: 'test_user',
          post: { title: '', body: 'This is the post content!', ip: '127.0.0.1' }
        }
      end

      it "don't create a post" do
        expect { post '/posts', params: invalid_params }
          .not_to change(Post, :count)
      end

      it 'returns unprocessable_entity status' do
        post '/posts', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation error message' do
        post '/posts', params: invalid_params
        json_response = response.parsed_body
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end
  end
end
