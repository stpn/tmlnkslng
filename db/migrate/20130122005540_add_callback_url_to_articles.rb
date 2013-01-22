class AddCallbackUrlToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :callback_url, :text
  end
end
