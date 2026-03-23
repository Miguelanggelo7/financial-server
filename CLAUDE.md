# CLAUDE.md

## Project
REST API in Rails 8 (API mode) with PostgreSQL.

## Stack

- **Rails 8** — API mode
- **PostgreSQL** — database
- **Devise + devise-jwt** — JWT authentication
- **Blueprinter** — JSON serializers
- **Sidekiq** — background jobs (use when necessary, not before)

## Authentication

Devise with devise-jwt is used. JWT tokens are sent in the `Authorization: Bearer <token>` header. Controllers requiring authentication use `before_action :authenticate_user!`.

Do not create alternative or custom authentication systems. Everything goes through Devise.

## Controller Structure

Controllers live under `app/controllers/api/v1/`. They always inherit from `Api::V1::BaseController`.

Thin controllers — no business logic. Only: authentication/authorization, strong params, call model or service object, and render JSON response.

```ruby
def create
  @order = Order.new(order_params)
  if @order.save
    render json: OrderBlueprint.render(@order), status: :created
  else
    render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
  end
end
```

## Models

Any query that repeats more than once should be a scope in the model. Never duplicate `where` conditions in controllers or services.

Validations always go in the model. Never in the controller.

Always use eager loading (`includes`, `preload`, `eager_load`) to avoid N+1.

## Service Objects

For complex business logic or when a model grows too large. They live in `app/services/`.

```ruby
# app/services/orders/create_service.rb
class Orders::CreateService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    # logic here
  end
end
```

## Serializers

Use **Blueprinter** for all JSON responses. Never render ActiveRecord models directly. Blueprints live in `app/blueprints/`.

```ruby
render json: UserBlueprint.render(@user)
render json: UserBlueprint.render(@users)
render json: UserBlueprint.render(@user, view: :with_orders)
```

## JSON Responses

```ruby
render json: UserBlueprint.render(@user), status: :ok
render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity
render json: { error: "Not found" }, status: :not_found
render json: { error: "Unauthorized" }, status: :unauthorized
```

## Background Jobs

Use Sidekiq for jobs. Never use `deliver_now` in requests — always use `deliver_later`.

## Database

- Add indexes on columns used in `where`, `order`, or as foreign keys.
- Use migrations for any schema changes.
- Add `null: false` and `default` in columns that require them directly in the migration.

## Tests

No tests exist. Do not generate specs or test files unless explicitly requested. When implemented: RSpec + FactoryBot.

## openapi.yaml

The `openapi.yaml` file at the project root is the source of truth for the API's HTTP contract.

### Mandatory flow when changing the API

When finishing any change that affects the HTTP contract, update `openapi.yaml` reflecting exactly what changed.

### What triggers an update

- Changes in `config/routes.rb`
- Changes in controller strong params
- New actions in controllers or new controllers
- Changes in blueprints affecting response fields
- New models with associated endpoints

### What does NOT trigger an update

- Internal logic changes in services or models with no HTTP interface impact
- Migrations that don't add/remove fields visible in the API
- Internal refactors without contract changes

## General Conventions

- Avoid ActiveRecord callbacks for business logic — use service objects.
- Do not use new gems without consulting first.