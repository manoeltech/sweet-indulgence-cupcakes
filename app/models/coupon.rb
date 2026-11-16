# Classe Promoção do PIT I, agora com validade e limite de uso (US06 RN#1).
class Coupon < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  normalizes :code, with: ->(code) { code.strip.upcase }

  validates :code, presence: { message: "Informe o código do cupom." }
  validates :code, uniqueness: { message: "Já existe um cupom com esse código." }
  validates :percentage, numericality: { only_integer: true, in: 1..90, message: "O desconto precisa ser de 1 a 90%." }
  validates :valid_until, presence: { message: "Informe a validade." }
  validates :usage_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # US06 CA#3: informa se o cupom é inválido, expirado ou esgotado.
  def self.find_valid!(code, today: Time.zone.today)
    code = code.to_s.strip.upcase
    return if code.empty?

    coupon = find_by(code: code)
    raise BusinessRuleError, "Cupom inválido." if coupon.nil? || !coupon.active?
    raise BusinessRuleError, "Este cupom expirou." if coupon.expired?(today)
    raise BusinessRuleError, "Este cupom atingiu o limite de usos." if coupon.exhausted?

    coupon
  end

  def expired?(today = Time.zone.today)
    valid_until < today
  end

  def exhausted?
    usage_limit.present? && uses_count >= usage_limit
  end

  def discount_on(amount)
    (amount.to_d * percentage / 100).round(2)
  end
end
