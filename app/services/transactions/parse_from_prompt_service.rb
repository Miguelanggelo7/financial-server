require "net/http"
require "json"

class Transactions::ParseFromPromptService
  GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions".freeze
  MODEL = "llama-3.3-70b-versatile".freeze

  def initialize(user:, amount_cents:, currency:, prompt:, locale: I18n.locale)
    @user = user
    @amount_cents = amount_cents
    @currency = currency
    @prompt = prompt
    @locale = locale
  end

  def call
    parsed = call_groq
    create_transaction(parsed)
  end

  private

  def categories_context
    @user.categories.map do |cat|
      "- id: #{cat.id}, name: #{cat.display_name}, description: #{cat.description}"
    end.join("\n")
  end

  def system_prompt
    <<~PROMPT
      You are a financial assistant that parses transaction descriptions.
      Return a JSON object with exactly these fields:
      - "description": a clean, concise description of the transaction (string)
      - "category_id": the most appropriate category ID from the list below (integer, must be one of the provided IDs)
      - "transacted_at": ISO 8601 datetime in UTC (use #{Time.current.iso8601} if not specified in the input)
      - "argumentation": a brief explanation of why you chose that category for this transaction (string)

      Available categories:
      #{categories_context}

      Respond in the language corresponding to the locale "#{@locale}".
      Respond ONLY with valid JSON. No extra text, no markdown, no code blocks.
    PROMPT
  end

  def call_groq
    uri = URI(GROQ_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{Rails.application.credentials.groq_api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: MODEL,
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: "Amount: #{@amount_cents} cents (#{@currency}). Transaction: #{@prompt}" }
      ],
      response_format: { type: "json_object" },
      temperature: 0
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Groq API error (#{response.code}): #{response.body}"
    end

    body = JSON.parse(response.body)
    JSON.parse(body.dig("choices", 0, "message", "content"))
  end

  def create_transaction(parsed)
    category_id = parsed["category_id"]
    unless @user.categories.exists?(category_id)
      raise "Invalid category returned by LLM: #{category_id}"
    end

    transaction = @user.transactions.new(
      amount_cents: @amount_cents,
      currency: @currency,
      description: parsed["description"],
      argumentation: parsed["argumentation"],
      category_id: category_id,
      transacted_at: parsed["transacted_at"]
    )

    unless transaction.save
      raise transaction.errors.full_messages.join(", ")
    end

    transaction
  end
end
