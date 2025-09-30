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
        expect(response).to have_http_status(422)
      end

      it 'returns validation error message' do
        post '/posts', params: invalid_params
        json_response = response.parsed_body
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end
  end

  describe 'GET /posts/top' do
    let!(:user) { User.create(login: 'test_user') }
    let!(:another_user) { User.create(login: 'another_user') }

    before do
      bad_post = user.posts.create!(title: 'Bad Post', body: '...', ip: '1.1.1.1')
      excellent_post = user.posts.create!(title: 'Excellent Post', body: '...', ip: '2.2.2.2')
      average_post = user.posts.create!(title: 'Average Post', body: '...', ip: '3.3.3.3')
      user.posts.create!(title: 'Unrated post', body: '...', ip: '4.4.4.4')

      bad_post.ratings.create!(user: user, value: 1)
      excellent_post.ratings.create!(user: user, value: 5)
      average_post.ratings.create!(user: user, value: 2)
      average_post.ratings.create!(user: another_user, value: 4)
    end

    context 'when requesting top N posts' do
      let(:count) { 2 }

      it 'returns the posts with the highest average rating in descending order' do
        get "/posts/top?count=#{count}"

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response.size).to eq(count)
        expect(json_response[0]['title']).to eq('Excellent Post')
        expect(json_response[1]['title']).to eq('Average Post')
        expect(json_response[0].keys).to contain_exactly('id', 'title', 'body')
      end
    end

    context 'when there are unrated posts' do
      let(:count) { 10 }

      it 'does not include posts that have no ratings' do
        get "/posts/top?count=#{count}"
        json_response = response.parsed_body

        expect(json_response.pluck('title')).not_to include('Unrated post')
        expect(json_response.size).to eq(3)
      end
    end
  end

  describe 'GET /posts/shared_ips' do
    let(:user_one) { User.create!(login: 'user_one') }
    let(:user_two) { User.create!(login: 'user_two') }
    let(:user_three) { User.create!(login: 'user_three') }

    before do
      user_one.posts.create!(title: 'First post', body: '...', ip: '1.1.1.1')
      user_two.posts.create!(title: 'Second post', body: '...', ip: '1.1.1.1')
      user_one.posts.create!(title: 'Third post', body: '...', ip: '2.2.2.2')
      user_one.posts.create!(title: 'Fourth post', body: '...', ip: '3.3.3.3')
      user_two.posts.create!(title: 'Fifth post', body: '...', ip: '3.3.3.3')
      user_three.posts.create!(title: 'Sixth post', body: '...', ip: '3.3.3.3')
    end

    it 'returns a list of IPs used by multiple authors with their logins' do
      get '/posts/shared_ips'

      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body

      expect(json_response.size).to eq(2)

      shared_ip1 = json_response.find { |item| item['ip'] == '1.1.1.1' }
      expect(shared_ip1).not_to be_nil
      expect(shared_ip1['logins']).to contain_exactly('user_one', 'user_two')

      shared_ip3 = json_response.find { |item| item['ip'] == '3.3.3.3' }
      expect(shared_ip3).not_to be_nil
      expect(shared_ip3['logins']).to contain_exactly('user_one', 'user_two', 'user_three')
    end
  end
end
