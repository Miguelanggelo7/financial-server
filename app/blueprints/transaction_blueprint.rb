class TransactionBlueprint < Blueprinter::Base
  identifier :id

  fields :amount_cents, :currency, :description, :transacted_at, :created_at, :updated_at

  field :amount do |transaction|
    transaction.amount_display
  end

  association :category, blueprint: CategoryBlueprint
end
