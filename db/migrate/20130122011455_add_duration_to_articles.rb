class AddDurationToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :duration, :text
  end
end
