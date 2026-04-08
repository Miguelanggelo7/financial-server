class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :wallet,   null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.bigint     :amount_cents,  null: false
      t.text       :description
      t.text       :argumentation
      t.text       :prompt
      t.date       :transacted_at, null: false

      t.timestamps
    end

    add_index :transactions, [:wallet_id, :transacted_at]
    add_index :transactions, [:wallet_id, :category_id]
  end
end
