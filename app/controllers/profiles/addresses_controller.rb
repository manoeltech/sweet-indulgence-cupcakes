class Profiles::AddressesController < ApplicationController
  require_login

  def create
    address = current_user.addresses.build(params.expect(address: [ :street, :number, :district, :zip_code ]))
    if address.save
      redirect_to profile_path, success: "Endereço salvo."
    else
      redirect_to profile_path, error: "Preencha todos os campos do endereço."
    end
  end
end
