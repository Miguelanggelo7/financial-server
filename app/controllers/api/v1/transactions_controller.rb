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
    parsed = get_params([
      { name: :amount_cents,  type: :int,    required: true  },
      { name: :transacted_at, type: :date,   required: true  },
      { name: :description,   type: :string, required: false },
      { name: :category_id,   type: :int,    required: false }
    ])
    return unless parsed

    @transaction = @wallet.transactions.new(parsed)
    if @transaction.save
      render json: TransactionBlueprint.render(@transaction), status: :created
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    parsed = get_params([
      { name: :amount_cents,  type: :int,    required: false },
      { name: :transacted_at, type: :date,   required: false },
      { name: :description,   type: :string, required: false },
      { name: :category_id,   type: :int,    required: false }
    ])
    return unless parsed

    if @transaction.update(parsed)
      render json: TransactionBlueprint.render(@transaction), status: :ok
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def parse_from_prompt
    parsed = get_params([
      { name: :transacted_at, type: :date,   required: true },
      { name: :prompt,        type: :string, required: true }
    ])
    return unless parsed

    transaction = Transactions::ParseFromPromptService.new(
      wallet: @wallet,
      transacted_at: parsed[:transacted_at],
      prompt: parsed[:prompt]
    ).call
    render json: TransactionBlueprint.render(transaction), status: :created
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

end
