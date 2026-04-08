class Api::V1::BaseController < ApplicationController
  before_action :set_locale
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  include Commons::Parameters

  private

  def set_locale
    requested = request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/\A[a-z]{2}/)&.first
    I18n.locale = I18n.available_locales.map(&:to_s).include?(requested) ? requested : I18n.default_locale
  end

  def record_not_found
    render json: { error: "Not found" }, status: :not_found
  end
end