# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ratings API', type: :request do
  describe 'POST /posts/:post_id/ratings' do
    let(:user) { User.create!(login: 'test_user') }
    let(:post_record) { user.posts.create!(title: 'A post', body: 'Some content', ip: '127.0.0.1') }

    context 'with valid parameters' do
      let(:valid_params) { { user_id: user.id, value: 4 } }

      it 'create a new assessment' do
        expect { post "/posts/#{post_record.id}/ratings", params: valid_params }.to change(Rating, :count).by(1)
      end

      it 'returns status 201 (created) and the new rating average' do
        post "/posts/#{post_record.id}/ratings", params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['average_rating']).to eq(4.0)
      end
    end

    context 'when the user tries to rate the same post twice' do
      it 'returns an error on the second attempt' do
        post "/posts/#{post_record.id}/ratings", params: { user_id: user.id, value: 5 }
        expect(response).to have_http_status(:created)

        post "/posts/#{post_record.id}/ratings", params: { user_id: user.id, value: 1 }
        expect(response).to have_http_status(422)

        json_response = response.parsed_body
        expect(json_response['errors']).to include('User can rate a post only once')
      end
    end

    context 'with an invalid evaluation value' do
      it 'returns a validation error' do
        invalid_params = { user_id: user.id, value: 6 }
        post "/posts/#{post_record.id}/ratings", params: invalid_params

        expect(response).to have_http_status(422)
        json_response = response.parsed_body
        expect(json_response['errors']).to include('Value is not included in the list')
      end
    end
  end
end
