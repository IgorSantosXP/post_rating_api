# frozen_string_literal: true

Rails.logger = Logger.new($stdout)
Rails.logger.level = Logger::INFO

require 'typhoeus'
require 'json'
require 'faker'

API_URL = 'http://localhost:3000'
NUM_USERS = 100
NUM_POSTS = 200_000
NUM_IPS = 50
RATING_PERCENTAGE = 0.75
BATCH_SIZE = 1000

Rails.logger.info 'Generating prerequisite data...'
user_logins = Array.new(NUM_USERS) { Faker::Internet.unique.username(specifier: 5..8) }
ip_addresses = Array.new(NUM_IPS) { Faker::Internet.ip_v4_address }
Rails.logger.info { "#{user_logins.size} logins and #{ip_addresses.size} generated IPs." }

hydra = Typhoeus::Hydra.new(max_concurrency: 200)
created_post_ids = []

Rails.logger.info 'Creating first post do warm up rails'

first_post = {
  login: user_logins.sample,
  post: {
    title: 'Warmup post',
    body: 'Just to warm up Rails',
    ip: ip_addresses.sample
  }
}
Typhoeus.post("#{API_URL}/posts", body: first_post.to_json, headers: { 'Content-Type' => 'application/json' })

Rails.logger.info { "Creating #{NUM_POSTS} posts in batches of #{BATCH_SIZE}..." }

# rubocop:disable Metrics/BlockLength
NUM_POSTS.times.each_slice(BATCH_SIZE) do |batch|
  batch.each do
    user_login = user_logins.sample
    post_body = {
      login: user_login,
      post: {
        title: Faker::Lorem.sentence(word_count: 3),
        body: Faker::Lorem.paragraph(sentence_count: 4),
        ip: ip_addresses.sample
      }
    }

    request = Typhoeus::Request.new(
      "#{API_URL}/posts",
      method: :post,
      headers: { 'Content-Type' => 'application/json' },
      body: post_body.to_json
    )

    request.on_complete do |response|
      if response.success?
        created_post_ids << JSON.parse(response.body)['id']
      else
        Rails.logger.info { "Post creation failed for user #{user_login}: #{response.status_message}" }
      end
    end

    hydra.queue(request)
  end

  hydra.run
  Rails.logger.info { "Posts created: #{created_post_ids.size}/#{NUM_POSTS}" }
end
# rubocop:enable Metrics/BlockLength

Rails.logger.info { "Post creation completed. #{created_post_ids.size} posts created successfully." }

all_user_ids = User.pluck(:id)
num_ratings = (created_post_ids.size * RATING_PERCENTAGE).to_i
posts_to_rate = created_post_ids.sample(num_ratings)

Rails.logger.info { "Creating #{num_ratings} ratings..." }
rating_processed = 0

posts_to_rate.each_slice(BATCH_SIZE) do |batch|
  batch.each do |post_id|
    next unless post_id

    rating_params = {
      rating: {
        user_id: all_user_ids.sample,
        value: rand(1..5)
      }
    }

    request = Typhoeus::Request.new(
      "#{API_URL}/posts/#{post_id}/ratings",
      method: :post,
      headers: { 'Content-Type' => 'application/json' },
      body: rating_params.to_json
    )

    request.on_complete do |response|
      unless response.success?
        Rails.logger.info { "Rating creation failed for post #{post_id}: #{response.status_message}" }
      end
    end

    hydra.queue(request)
    rating_processed += 1
  end

  hydra.run
  Rails.logger.info { "Ratings processed: #{rating_processed}/#{num_ratings}" }
end

Rails.logger.info 'Seeding process complete!'
