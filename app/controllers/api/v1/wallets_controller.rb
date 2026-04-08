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
    @wallet = current_user.wallets.new(wallet_params)
    if @wallet.save
      render json: WalletBlueprint.render(@wallet), status: :created
    else
      render json: { errors: @wallet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @wallet.update(wallet_params)
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

  def wallet_params
    params.require(:wallet).permit(:name, :currency)
  end
end
