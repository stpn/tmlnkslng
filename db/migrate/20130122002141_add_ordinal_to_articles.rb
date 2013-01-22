class AddOrdinalToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :ordinal, :text
  end
end
