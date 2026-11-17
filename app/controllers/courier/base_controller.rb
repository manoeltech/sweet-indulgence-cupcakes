# Área do entregador: só usuários com papel courier.
class Courier::BaseController < ApplicationController
  require_role :courier

  private

  # US16 RN#1: o entregador só vê os pedidos dele que já saíram para entrega.
  def my_deliveries
    current_user.deliveries.out_for_delivery
  end

  def find_delivery(code)
    my_deliveries.find_by(code: code) or raise ActiveRecord::RecordNotFound
  end
end
