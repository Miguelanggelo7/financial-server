class Api::V1::WalletsController < Api::V1::BaseController
  before_action :set_wallet, only: %i[show update destroy]

  def index
    @wallets = current_user.wallets
    render json: WalletBlueprint.render(@wallets), status: :ok
  end

  def show
    render json: WalletBlueprint.render(@wallet), status: :ok
  end

  def create
    parsed = get_params([
      { name: :name,     type: :string, required: true  },
      { name: :currency, type: :string, required: true  }
    ])
    return unless parsed

    @wallet = current_user.wallets.new(parsed)
    if @wallet.save
      render json: WalletBlueprint.render(@wallet), status: :created
    else
      render json: { errors: @wallet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    parsed = get_params([
      { name: :name,     type: :string, required: false },
      { name: :currency, type: :string, required: false }
    ])
    return unless parsed

    if @wallet.update(parsed)
      render json: WalletBlueprint.render(@wallet), status: :ok
    else
      render json: { errors: @wallet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @wallet.destroy
    render json: { message: "Wallet deleted." }, status: :ok
  end

  private

  def set_wallet
    @wallet = current_user.wallets.find(params[:id])
  end

end
