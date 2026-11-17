# Foto enviada pelo administrador. A URL leva a data da foto (?v=), então pode ficar em cache por muito tempo.
class Cupcakes::PhotosController < ApplicationController
  def show
    photo = CupcakePhoto.find_by!(cupcake_id: params[:cupcake_id])
    expires_in 1.year, public: true
    send_data photo.data, type: photo.content_type, disposition: :inline
  end
end
