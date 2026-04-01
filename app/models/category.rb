class Category < ApplicationRecord
  DEFAULT_KEYS = %w[home leisure subscriptions food transport other].freeze

  belongs_to :user
  has_many :transactions, dependent: :restrict_with_error

  validates :key, inclusion: { in: DEFAULT_KEYS }, allow_blank: true
  validates :key, uniqueness: { scope: :user_id }, allow_blank: true
  validates :name, presence: true, if: -> { key.blank? }

  scope :for_user, ->(user) { where(user: user) }
  scope :defaults, -> { where.not(key: nil) }
  scope :custom, -> { where(key: nil) }

  def display_name
    key.present? ? I18n.t("categories.#{key}.name") : name
  end

  def display_description
    key.present? ? I18n.t("categories.#{key}.description") : description
  end

  def default?
    key.present?
  end
end
