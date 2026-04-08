class Api::V1::CategoriesController < Api::V1::BaseController
  def index
    @categories = current_user.categories.order(:created_at)
    render json: CategoryBlueprint.render(@categories), status: :ok
  end

  def create
    parsed = get_params([
      { name: :name,        type: :string, required: true  },
      { name: :description, type: :string, required: false }
    ])
    return unless parsed

    @category = current_user.categories.new(parsed)
    if @category.save
      render json: CategoryBlueprint.render(@category), status: :created
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @category = current_user.categories.find(params[:id])
    if @category.destroy
      render json: { message: "Category deleted." }, status: :ok
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

end
