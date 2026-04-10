require "net/http"

class Api::V1::EnablebankingController < Api::V1::BaseController
  ENABLEBANKING_API = "https://api.enablebanking.com"

  # POST /api/v1/enablebanking/token
  # Genera un JWT firmado con la clave RSA del certificado y lo devuelve.
  def create
    render json: { token: generate_jwt }, status: :ok
  rescue OpenSSL::PKey::RSAError => e
    render json: { error: "Invalid private key: #{e.message}" }, status: :unprocessable_entity
  end

  # GET /api/v1/enablebanking/aspsps
  # Devuelve la lista de ASPSPs disponibles en Enable Banking.
  def list_available_aspsp
    uri = URI("#{ENABLEBANKING_API}/aspsps")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{generate_jwt}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

    if response.is_a?(Net::HTTPSuccess)
      render json: JSON.parse(response.body), status: :ok
    else
      render json: { error: JSON.parse(response.body) }, status: response.code.to_i
    end
  rescue SocketError, Net::OpenTimeout => e
    render json: { error: e.message }, status: :service_unavailable
  end

  private

  def generate_jwt
    application_id = Rails.application.credentials.eb_application_id
    key_path = "../#{application_id}.pem"
    rsa_key = OpenSSL::PKey::RSA.new(File.read(key_path))

    iat = Time.now.to_i
    payload = { iss: "enablebanking.com", aud: "api.enablebanking.com", iat: iat, exp: iat + 3600 }
    headers = { typ: "JWT", alg: "RS256", kid: application_id }

    JWT.encode(payload, rsa_key, "RS256", headers)
  end
end