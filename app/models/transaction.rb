class Transaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :category

  has_one :user, through: :wallet

  delegate :currency, to: :wallet

  validates :amount_cents,  presence: true, numericality: { only_integer: true, other_than: 0 }
  validates :transacted_at, presence: true

  scope :for_user,      ->(user)      { joins(:wallet).where(wallets: { user_id: user.id }) }
  scope :by_date,       ->            { order(transacted_at: :desc) }
  scope :in_date_range, ->(from, to)  { where(transacted_at: from..to) }
  scope :for_category,  ->(category)  { where(category: category) }
  scope :income,        ->            { where("amount_cents > 0") }
  scope :expenses,      ->            { where("amount_cents < 0") }
  scope :with_category, ->            { includes(:category) }

  def amount
    BigDecimal(amount_cents.to_s) / BigDecimal("100")
  end

  def amount_display
    format("%.2f", amount)
  end
end
