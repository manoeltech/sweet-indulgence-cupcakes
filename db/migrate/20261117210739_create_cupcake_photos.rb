# Foto enviada pelo administrador. Fica no banco (e não em disco) porque o disco
# do Render gratuito é apagado a cada reinício; tabela própria para a vitrine não
# carregar os bytes junto com cada cupcake.
class CreateCupcakePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :cupcake_photos do |t|
      t.references :cupcake, index: { unique: true }, null: false, foreign_key: true
      t.string :content_type, null: false
      t.binary :data, null: false

      t.timestamps
    end
  end
end
