class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_wallet
  before_action :set_transaction, only: %i[show update destroy]

  def index
    @transactions = @wallet.transactions
                           .with_category
                           .by_date
    render json: TransactionBlueprint.render(@transactions), status: :ok
  end

  def show
    render json: TransactionBlueprint.render(@transaction), status: :ok
  end

  def create
    @transaction = @wallet.transactions.new(transaction_params)
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
    transacted_at = parse_transacted_at(params.require(:transacted_at))
    prompt = params.require(:prompt).presence

    return render json: { error: "transacted_at is not a valid date" }, status: :bad_request if transacted_at.nil?
    return render json: { error: "prompt can't be blank" }, status: :bad_request if prompt.nil?

    transaction = Transactions::ParseFromPromptService.new(
      wallet: @wallet,
      transacted_at: transacted_at,
      prompt: prompt
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

  def set_wallet
    @wallet = current_user.wallets.find(params[:wallet_id])
  end

  def set_transaction
    @transaction = @wallet.transactions.find(params[:id])
  end

  def parse_transacted_at(value)
    DateTime.iso8601(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def transaction_params
    params.require(:transaction).permit(
      :amount_cents,
      :description,
      :transacted_at,
      :category_id
    )
  end
end
