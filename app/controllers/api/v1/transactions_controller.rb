class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_transaction, only: %i[show update destroy]

  def index
    @transactions = current_user.transactions
                                .with_category
                                .by_date
    render json: TransactionBlueprint.render(@transactions), status: :ok
  end

  def show
    render json: TransactionBlueprint.render(@transaction), status: :ok
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    if @transaction.save
      render json: TransactionBlueprint.render(@transaction), status: :created
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      render json: TransactionBlueprint.render(@transaction), status: :ok
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def parse_from_prompt
    transaction = Transactions::ParseFromPromptService.new(
      user: current_user,
      amount_cents: params.require(:amount_cents).to_i,
      currency: params.fetch(:currency, "USD"),
      prompt: params.require(:prompt)
    ).call
    render json: TransactionBlueprint.render(transaction), status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @transaction.destroy
    render json: { message: "Transaction deleted." }, status: :ok
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(
      :amount_cents,
      :currency,
      :description,
      :transacted_at,
      :category_id
    )
  end
end
