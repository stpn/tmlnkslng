class AddPercentToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :percent, :text
  end
end
