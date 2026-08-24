class LoadQueueSchema < ActiveRecord::Migration[8.1]
  def change
    load Rails.root.join("db/queue_schema.rb")
  end
end
