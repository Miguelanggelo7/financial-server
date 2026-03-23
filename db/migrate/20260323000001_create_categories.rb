class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key
      t.string :name
      t.text :description

      t.timestamps
    end

    add_index :categories, [ :user_id, :key ], unique: true, where: "key IS NOT NULL"
  end
end
