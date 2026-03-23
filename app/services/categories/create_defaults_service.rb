class Categories::CreateDefaultsService
  def initialize(user:)
    @user = user
  end

  def call
    Category::DEFAULT_KEYS.each do |key|
      @user.categories.create!(key: key)
    end
  end
end
