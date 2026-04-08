class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.references :user,     null: false, foreign_key: true
      t.string     :name,     null: false
      t.integer    :currency, null: false

      t.timestamps
    end

    add_index :wallets, [:user_id, :name], unique: true
  end
end
