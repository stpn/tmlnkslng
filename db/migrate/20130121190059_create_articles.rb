class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.text :code
      t.text :person
      t.text :location
      t.text :organization
      t.text :misc
      t.text :date
      t.text :time
      t.text :money
      t.text :number

      t.timestamps
    end
  end
end
