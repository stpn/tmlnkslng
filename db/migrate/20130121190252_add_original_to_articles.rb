class AddOriginalToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :original, :text
  end
end
