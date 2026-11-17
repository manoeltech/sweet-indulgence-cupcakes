ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    APPROVED_CARD = { number: "4111 1111 1111 1111", name: "CLIENTE TESTE", expiry: "12/30", cvv: "123" }.freeze
    DECLINED_CARD = APPROVED_CARD.merge(number: "4000 0000 0000 0002").freeze

    def place_order(customer: users(:cliente), cart: { cupcakes(:red_velvet).id => 2 }, **options)
      Order.place!(customer: customer, cart: cart, fulfillment: "delivery", payment_method: "credit",
                   address: "Rua A, 10 – Centro", delivery_zone_id: delivery_zones(:centro).id,
                   card: APPROVED_CARD, **options)
    end
  end
end

module SignInHelper
  def sign_in_as(user)
    post session_path, params: { email: user.email, password: "cupcake123" }
  end
end

ActionDispatch::IntegrationTest.include SignInHelper
