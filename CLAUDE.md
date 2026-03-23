# CLAUDE.md

## Proyecto
API REST en Rails 8 (API mode) con PostgreSQL.

## Stack

- **Rails 8** — API mode
- **PostgreSQL** — base de datos
- **Devise + devise-jwt** — autenticación con JWT
- **Blueprinter** — serializers JSON
- **Sidekiq** — background jobs (usar cuando sea necesario, no antes)

## Autenticación

Se usa Devise con devise-jwt. Los tokens JWT se envían en el header `Authorization: Bearer <token>`. Los controllers que requieren autenticación usan `before_action :authenticate_user!`.

No crear sistemas de autenticación alternativos ni custom. Todo pasa por Devise.

## Estructura de controllers

Los controllers viven bajo `app/controllers/api/v1/`. Siempre heredan de `Api::V1::BaseController`.

Controllers delgados — sin lógica de negocio. Solo:
1. Autenticación/autorización
2. Parámetros permitidos (strong params)
3. Llamar al modelo o service object
4. Renderizar respuesta JSON

```ruby
# Bien
def create
  @order = Order.new(order_params)
  if @order.save
    render json: OrderBlueprint.render(@order), status: :created
  else
    render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
  end
end

# Mal — lógica de negocio en el controller
def create
  @order = Order.new(order_params)
  @order.total = @order.items.sum(&:price) * 1.21
  @order.status = "pending"
  UserMailer.order_confirmation(@order).deliver_later
  ...
end
```

## Modelos

### Scopes obligatorios
Toda consulta que se repita más de una vez en el código debe ser un scope en el modelo correspondiente. Nunca duplicar condiciones where en controllers o services.

```ruby
# En el modelo
scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }
scope :by_status, ->(status) { where(status: status) }
scope :created_between, ->(from, to) { where(created_at: from..to) }

# Uso correcto
User.active.recent
Order.by_status("pending").created_between(1.week.ago, Time.current)
```

### Validaciones
Las validaciones van siempre en el modelo. Nunca validar en el controller.

### Asociaciones
Siempre usar eager loading para evitar N+1. Usar `includes`, `preload` o `eager_load` según el caso.

```ruby
# Mal
@orders = Order.all
@orders.each { |o| puts o.user.name } # N+1

# Bien
@orders = Order.includes(:user).all
```

## Service objects

Usar service objects para lógica de negocio compleja o cuando un modelo empieza a crecer demasiado. Viven en `app/services/`.

```ruby
# app/services/orders/create_service.rb
class Orders::CreateService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    # lógica aquí
  end
end

# Uso en controller
Orders::CreateService.new(user: current_user, params: order_params).call
```

## Serializers

Usar **Blueprinter** para todas las respuestas JSON. Nunca renderizar modelos ActiveRecord directamente con `render json: @model`.

Los blueprints viven en `app/blueprints/` con el nombre `NombreBlueprint`.

```ruby
# app/blueprints/user_blueprint.rb
class UserBlueprint < Blueprinter::Base
  identifier :id
  fields :email, :name, :created_at

  # Vista con datos adicionales
  view :with_orders do
    association :orders, blueprint: OrderBlueprint
  end

  # Vista reducida para listados
  view :summary do
    fields :email, :name
  end
end
```

```ruby
# En el controller
render json: UserBlueprint.render(@user)                         # objeto único
render json: UserBlueprint.render(@users)                        # colección
render json: UserBlueprint.render(@user, view: :with_orders)    # vista específica
```

## Respuestas JSON

Respuestas consistentes en toda la API. Siempre usar Blueprinter para el data:

```ruby
# Éxito
render json: UserBlueprint.render(@user), status: :ok
render json: UserBlueprint.render(@user), status: :created

# Error de validación
render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity

# No encontrado
render json: { error: "Not found" }, status: :not_found

# No autorizado
render json: { error: "Unauthorized" }, status: :unauthorized
```

## Background Jobs

Cuando sea necesario usar jobs, usar **Sidekiq**. Los jobs viven en `app/jobs/`. Nunca usar `deliver_now` para emails en requests — siempre `deliver_later`.

```ruby
# Bien
UserMailer.welcome(@user).deliver_later

# Mal en un request
UserMailer.welcome(@user).deliver_now
```

## Base de datos

- Siempre añadir índices en columnas usadas en `where`, `order` o como foreign keys.
- Usar migraciones para cualquier cambio de esquema, nunca editar el schema directamente.
- Añadir `null: false` y `default` en columnas que lo requieran directamente en la migración.

```ruby
# Bien en migración
add_index :users, :email, unique: true
add_index :orders, [:user_id, :status]
t.string :status, null: false, default: "pending"
```

## Tests

No hay tests de momento. Cuando se implementen, usar RSpec + FactoryBot.

No generar specs ni archivos de test a menos que se pida explícitamente.

## Convenciones generales

- Nombres de clases en inglés, siempre.
- Métodos y variables en snake_case.
- Constantes en SCREAMING_SNAKE_CASE.
- Evitar callbacks de ActiveRecord (`before_save`, `after_create`, etc.) para lógica de negocio — usar service objects en su lugar.
- No usar gemas nuevas sin consultarlo primero.