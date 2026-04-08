module Commons::Parameters
  extend ActiveSupport::Concern

  private

  def get_params(definitions)
    definitions.each_with_object({}) do |defn, result|
      name  = defn[:name]
      raw   = params[name]

      next if raw.blank? && !defn[:required]
      return render_param_error("Missing required parameter: #{name}") if raw.blank?

      parsed = send(:"parse_#{defn[:type]}", raw)
      return render_param_error("Invalid value for parameter '#{name}': expected #{defn[:type]}") if parsed.nil?

      result[name] = parsed
    end
  end

  def render_param_error(message)
    render json: { success: false, error: message }, status: :bad_request
    false
  end

  def parse_int(value)    = Integer(value) rescue nil
  def parse_date(value)   = Date.strptime(value, "%Y/%m/%d") rescue nil
  def parse_string(value) = value.to_s
  def parse_bool(value)   = ActiveModel::Type::Boolean.new.cast(value)
  def parse_array(value)  = value.is_a?(Array) ? value : nil
end
