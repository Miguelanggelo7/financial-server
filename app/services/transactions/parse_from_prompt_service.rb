require "net/http"
require "json"

class Transactions::ParseFromPromptService
  GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions".freeze
  MODEL = "llama-3.3-70b-versatile".freeze

  def initialize(wallet:, transacted_at:, prompt:, locale: I18n.locale)
    @wallet = wallet
    @transacted_at = transacted_at
    @prompt = prompt
    @locale = locale
  end

  def call
    parsed = call_groq
    puts parsed.inspect
    create_transaction(parsed)
  end

  private

  def categories_context
    @wallet.user.categories.map do |cat|
      "- id: #{cat.id}, name: #{cat.display_name}, description: #{cat.description}"
    end.join("\n")
  end

  def system_prompt
    <<~PROMPT
      You are a financial assistant that parses transaction descriptions.
      Return a JSON object with exactly these fields:
      - "amount_cents": the transaction amount in cents as an integer. Convert the amount to cents by multiplying by 100 (e.g. "10 dollars" → 1000, "52 mil" → 5200000, "1.5k" → 150000, "200" → 20000, "10.50" → 1050). Parse abbreviations, shorthand, and natural language numbers. IMPORTANT: "10 dollars" = 1000 cents, NOT 100000. The wallet currency is #{@wallet.currency.upcase}.
      - "description": a clean, concise description of the transaction (string)
      - "category_id": the most appropriate category ID from the list below (integer, must be one of the provided IDs)
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
        { role: "user", content: @prompt }
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
    unless @wallet.user.categories.exists?(category_id)
      raise "Invalid category returned by LLM: #{category_id}"
    end

    transaction = @wallet.transactions.new(
      amount_cents: parsed["amount_cents"],
      description: parsed["description"],
      argumentation: parsed["argumentation"],
      category_id: category_id,
      transacted_at: @transacted_at
    )

    unless transaction.save
      raise transaction.errors.full_messages.join(", ")
    end

    transaction
  end
end
