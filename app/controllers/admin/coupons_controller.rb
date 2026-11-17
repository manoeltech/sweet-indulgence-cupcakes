# US06: o administrador cria cupons com desconto, validade e limite de usos.
class Admin::CouponsController < Admin::BaseController
  def index
    @coupons = Coupon.order(valid_until: :desc)
    @coupon = Coupon.new
  end

  def create
    @coupon = Coupon.new(params.expect(coupon: [ :code, :description, :percentage, :valid_until, :usage_limit ]))
    if @coupon.save
      redirect_to admin_coupons_path, success: "Cupom #{@coupon.code} criado."
    else
      @coupons = Coupon.order(valid_until: :desc)
      flash.now[:error] = @coupon.errors.map(&:message).uniq.to_sentence
      render :index, status: :unprocessable_entity
    end
  end
end
