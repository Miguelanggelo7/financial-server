class Wallet < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  enum :currency, { usd: 0, eur: 1, ves: 2 }

  validates :name,     presence: true, uniqueness: { scope: :user_id }
  validates :currency, presence: true

  def balance_cents
    transactions.sum(:amount_cents)
  end
end
