# US09: notificações dentro do app (o push nativo fica para a versão mobile).
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  scope :unread, -> { where(read: false) }
  scope :recent_first, -> { order(created_at: :desc) }

  # US09 RNF#2: respeita a preferência do cliente.
  def self.notify(customer, order, message)
    create!(user: customer, order: order, message: message) if customer.notifications_enabled?
  end

  def self.to_admins(message)
    User.admin.find_each { |admin| create!(user: admin, message: message) }
  end
end
