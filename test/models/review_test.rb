require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup { @order = place_order }

  test "só avalia depois da entrega (US10 RN#1)" do
    review = Review.new(user: users(:cliente), order: @order, cupcake: cupcakes(:red_velvet), rating: 5, delivery_rating: 5)

    assert_not review.valid?
    assert_includes review.errors[:base], "Você poderá avaliar depois que o pedido for entregue."
  end

  test "avalia uma vez cada cupcake do pedido" do
    @order.update!(status: "delivered")
    Review.create!(user: users(:cliente), order: @order, cupcake: cupcakes(:red_velvet), rating: 5, delivery_rating: 4)
    repeated = Review.new(user: users(:cliente), order: @order, cupcake: cupcakes(:red_velvet), rating: 3, delivery_rating: 3)

    assert_not repeated.valid?
    assert_equal BigDecimal("5"), cupcakes(:red_velvet).average_rating
  end

  test "nota precisa ser de 1 a 5 e o cupcake precisa estar no pedido" do
    @order.update!(status: "delivered")
    review = Review.new(user: users(:cliente), order: @order, cupcake: cupcakes(:morango), rating: 6, delivery_rating: 0)

    assert_not review.valid?
    assert_includes review.errors[:base], "Este cupcake não faz parte do pedido."
    assert_includes review.errors[:rating], "Dê uma nota de 1 a 5 estrelas para o cupcake e para a entrega."
  end
end
