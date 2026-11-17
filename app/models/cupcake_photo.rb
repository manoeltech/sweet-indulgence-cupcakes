# Foto do produto enviada pelo administrador, guardada no banco (o disco do Render gratuito é apagado a cada reinício).
class CupcakePhoto < ApplicationRecord
  MAX_BYTES = 2.megabytes
  # O tipo vem dos primeiros bytes do arquivo, não do que o navegador informa.
  SIGNATURES = {
    "image/jpeg" => ->(bytes) { bytes.start_with?("\xFF\xD8\xFF".b) },
    "image/png" => ->(bytes) { bytes.start_with?("\x89PNG\r\n\x1A\n".b) },
    "image/webp" => ->(bytes) { bytes.start_with?("RIFF".b) && bytes.byteslice(8, 4) == "WEBP".b }
  }.freeze

  belongs_to :cupcake

  def self.content_type_of(bytes)
    SIGNATURES.find { |_, matches| matches.call(bytes) }&.first
  end
end
