class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.bigint     :amount_cents,  null: false
      t.string     :currency,      null: false, default: "USD", limit: 3
      t.text       :description
      t.datetime   :transacted_at, null: false

      t.timestamps
    end

    add_index :transactions, [:user_id, :transacted_at]
    add_index :transactions, [:user_id, :category_id]
  end
end
