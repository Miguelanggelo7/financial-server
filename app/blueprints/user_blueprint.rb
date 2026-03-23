class UserBlueprint < Blueprinter::Base
  identifier :id
  fields :email, :full_name
end