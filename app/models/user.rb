# Cliente, Administrador e Entregador do diagrama de classes do PIT I.
#
# Revisão do PIT II: as três classes tinham os mesmos atributos (nome, e-mail),
# então viraram uma única tabela com o campo `role`, evitando três logins diferentes.
class User < ApplicationRecord
  has_secure_password

  enum :role, { customer: "customer", admin: "admin", courier: "courier" }, default: :customer

  has_many :addresses, dependent: :destroy
  has_many :orders, foreign_key: :customer_id, inverse_of: :customer, dependent: :restrict_with_error
  has_many :deliveries, class_name: "Order", foreign_key: :courier_id, inverse_of: :courier, dependent: :nullify
  has_many :favorites, dependent: :destroy
  has_many :favorite_cupcakes, through: :favorites, source: :cupcake
  has_many :notifications, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: { message: "Informe seu nome." }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Informe um e-mail válido." }
  validates :email, uniqueness: { message: "Já existe uma conta com este e-mail." }
  validates :password, length: { minimum: 6, message: "A senha precisa ter pelo menos 6 caracteres." }, allow_nil: true

  def first_name
    name.split.first
  end

  def favorited?(cupcake)
    favorites.any? { |favorite| favorite.cupcake_id == cupcake.id }
  end

  def unread_notifications_count
    notifications.unread.count
  end
end
