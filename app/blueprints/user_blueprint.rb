class UserBlueprint < Blueprinter::Base
  identifier :id
  fields :email, :name

  view :with_profile do
    fields :phone, :address
  end
end