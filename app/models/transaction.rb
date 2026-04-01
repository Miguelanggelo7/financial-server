class Transaction < ApplicationRecord
  SUPPORTED_CURRENCIES = %w[USD EUR USDT].freeze

  belongs_to :user
  belongs_to :category

  validates :amount_cents,  presence: true, numericality: { only_integer: true, other_than: 0 }
  validates :currency,      presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :transacted_at, presence: true

  scope :for_user,      ->(user)      { where(user: user) }
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
