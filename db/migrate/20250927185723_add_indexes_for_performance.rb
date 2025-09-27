class AddIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    add_index :ratings, [:user_id, :post_id], unique: true
    add_index :posts, :ip
  end
end
