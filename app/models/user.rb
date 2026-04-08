class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :categories,   dependent: :destroy
  has_many :wallets,      dependent: :destroy
  has_many :transactions, through: :wallets

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
