# US18 RN#1: contatos do entregador com o cliente ficam registrados para auditoria.
class ContactLog < ApplicationRecord
  belongs_to :order
  belongs_to :courier, class_name: "User"

  enum :channel, { call: "call", whatsapp: "whatsapp" }
end
