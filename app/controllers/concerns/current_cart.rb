module CurrentCart
  extend ActiveSupport::Concern

  included do
    helper_method :cart
  end

  private

  def cart
    @cart ||= Cart.new(session)
  end
end
