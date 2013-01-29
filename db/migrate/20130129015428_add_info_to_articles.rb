class AddInfoToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :info, :text
  end
end
