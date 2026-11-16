# US16: lista e detalhes das entregas, com o endereço aberto no GPS.
class Courier::DeliveriesController < Courier::BaseController
  def index
    @orders = my_deliveries.includes(:customer).order(:updated_at)
  end

  def show
    @order = find_delivery(params[:id])
    @map_url = "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(@order.delivery_address)}"
  end
end
