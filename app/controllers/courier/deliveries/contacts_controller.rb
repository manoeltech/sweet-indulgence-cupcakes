# US18: ligar ou mandar WhatsApp para o cliente; o contato fica registrado (RN#1).
class Courier::Deliveries::ContactsController < Courier::BaseController
  def create
    order = find_delivery(params[:delivery_id])
    channel = params[:channel] == "whatsapp" ? "whatsapp" : "call"
    order.contact_logs.create!(courier: current_user, channel: channel)

    phone = order.customer.phone.to_s.gsub(/\D/, "")
    return redirect_to(courier_delivery_path(order), error: "O cliente não cadastrou telefone.") if phone.empty?

    redirect_to contact_url(channel, phone, order), allow_other_host: true
  end

  private

  def contact_url(channel, phone, order)
    return "tel:+55#{phone}" if channel == "call"

    text = ERB::Util.url_encode("Olá! Sou o entregador da Sweet Indulgence com o pedido ##{order.code}.")
    "https://wa.me/55#{phone}?text=#{text}"
  end
end
