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

Controllers delgados — sin lógica de negocio. Solo: autenticación/autorización, strong params, llamar al modelo o service object, y renderizar respuesta JSON.

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

## Modelos

Toda query que se repita más de una vez debe ser un scope en el modelo. Nunca duplicar condiciones `where` en controllers o services.

Las validaciones van siempre en el modelo. Nunca en el controller.

Siempre usar eager loading (`includes`, `preload`, `eager_load`) para evitar N+1.

## Service objects

Para lógica de negocio compleja o cuando un modelo crece demasiado. Viven en `app/services/`.

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
```

## Serializers

Usar **Blueprinter** para todas las respuestas JSON. Nunca renderizar modelos ActiveRecord directamente. Los blueprints viven en `app/blueprints/`.

```ruby
render json: UserBlueprint.render(@user)
render json: UserBlueprint.render(@users)
render json: UserBlueprint.render(@user, view: :with_orders)
```

## Respuestas JSON

```ruby
render json: UserBlueprint.render(@user), status: :ok
render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity
render json: { error: "Not found" }, status: :not_found
render json: { error: "Unauthorized" }, status: :unauthorized
```

## Background Jobs

Sidekiq para jobs. Nunca `deliver_now` en requests — siempre `deliver_later`.

## Base de datos

- Añadir índices en columnas usadas en `where`, `order` o como foreign keys.
- Usar migraciones para cualquier cambio de esquema.
- Añadir `null: false` y `default` en columnas que lo requieran directamente en la migración.

## Tests

No hay tests. No generar specs ni archivos de test salvo que se pida explícitamente. Cuando se implementen: RSpec + FactoryBot.

## Postman — sincronización automática

Cuando modifiques algo relacionado con la API (rutas, parámetros, request/response bodies, nuevos endpoints, autenticación), debes actualizar Postman automáticamente al terminar el cambio de código.

### IDs de referencia

| Recurso | ID |
|---|---|
| Workspace | `ba21554e-7bcd-419b-a1cc-7caf1fe8ebf6` |
| Spec (OpenAPI) | `9baf9355-5a8a-4bda-a5d9-c8f0c2dccc12` |
| Collection | `f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0` |
| Environment | `454c17d6-1c40-41c3-a295-f633cab99e3d` |

### Flujo obligatorio al cambiar la API

**1. Actualizar el spec OpenAPI** con `mcp__postman__updateSpecFile`:
- `specId`: `9baf9355-5a8a-4bda-a5d9-c8f0c2dccc12`
- `path`: `openapi.yaml`
- Reflejar exactamente los cambios: nuevas rutas, parámetros añadidos/eliminados, bodies, responses.

**2. Sincronizar la colección** con `mcp__postman__syncCollectionWithSpec`:
- `specId`: `9baf9355-5a8a-4bda-a5d9-c8f0c2dccc12`
- `collectionId`: `43952046-f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0`

**3. Re-aplicar scripts** en los requests nuevos o modificados con `mcp__postman__updateCollectionRequest`:
- `collectionId`: `f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0`
- Sign Up / Sign In → script test que guarda `bearerToken` desde el header `Authorization`
- Sign Out → script test que limpia `bearerToken`
- List Categories → script test que guarda `category_id` desde `response.json()[0].id`
- Create Category → script test que guarda `category_id` desde `response.json().id`
- Sign Up / Sign In usan `auth: { type: "noauth" }` (la autenticación la maneja la colección a nivel global)

### Qué dispara la actualización

- Cambios en `config/routes.rb`
- Cambios en strong params de cualquier controller
- Nuevos actions en controllers o nuevos controllers
- Cambios en blueprints que afecten los campos del response
- Nuevos modelos con endpoints asociados

### Qué NO dispara la actualización

- Cambios internos de lógica en services o modelos sin impacto en la interfaz HTTP
- Migraciones que no añadan/eliminen campos visibles en la API
- Refactors internos sin cambio de contrato

## Convenciones generales

- Evitar callbacks de ActiveRecord para lógica de negocio — usar service objects.
- No usar gemas nuevas sin consultarlo primero.