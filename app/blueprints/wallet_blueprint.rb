class WalletBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :currency, :created_at, :updated_at

  field :balance_cents do |wallet|
    wallet.balance_cents
  end
end
