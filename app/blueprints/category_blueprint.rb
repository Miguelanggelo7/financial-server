class CategoryBlueprint < Blueprinter::Base
  identifier :id

  field :name do |category|
    category.display_name
  end

  field :description do |category|
    category.display_description
  end

  field :is_default do |category|
    category.default?
  end

  field :key
  field :created_at
  field :updated_at
end
