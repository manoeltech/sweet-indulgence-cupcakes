# US17: o entregador marca como entregue depois de confirmar com o cliente.
class Courier::Deliveries::CompletionsController < Courier::BaseController
  def create
    order = find_delivery(params[:delivery_id])
    unless params[:confirmed] == "1"
      return redirect_to courier_delivery_path(order), error: "Confirme com o cliente antes de marcar como entregue."
    end

    order.advance_to!("delivered", by: current_user)
    redirect_to courier_deliveries_path, success: "Pedido ##{order.code} entregue!"
  end
end
