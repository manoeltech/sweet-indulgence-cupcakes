# US16: lista e detalhes das entregas, com o endereço aberto no GPS.
class Courier::DeliveriesController < Courier::BaseController
  # A lista também mostra o que já foi atribuído e ainda está na loja, para a notificação
  # "Você recebeu o pedido" não levar a uma lista vazia. Só os que saíram abrem para entregar.
  def index
    @orders = current_user.deliveries.where(status: %w[out_for_delivery preparing paid])
                          .includes(:customer).in_order_of(:status, %w[out_for_delivery preparing paid]).order(:updated_at)
  end

  def show
    @order = find_delivery(params[:id])
    @map_url = "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(@order.delivery_address)}"
  end
end
