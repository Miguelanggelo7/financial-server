class Api::V1::CategoriesController < Api::V1::BaseController
  def index
    puts request.headers["Authorization"]
    puts current_user
    @categories = current_user.categories.order(:created_at)
    render json: CategoryBlueprint.render(@categories), status: :ok
  end

  def create
    @category = current_user.categories.new(category_params)
    if @category.save
      render json: CategoryBlueprint.render(@category), status: :created
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @category = current_user.categories.find(params[:id])
    @category.destroy
    render json: { message: "Category deleted." }, status: :ok
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end
end
