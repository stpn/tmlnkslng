class AddProcessedToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :processed, :boolean
  end
end
