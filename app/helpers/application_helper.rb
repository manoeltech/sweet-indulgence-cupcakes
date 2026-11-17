module ApplicationHelper
  FLASH_CLASSES = { "success" => "msg-sucesso", "error" => "msg-erro", "warning" => "msg-aviso", "notice" => "msg-sucesso", "alert" => "msg-erro" }.freeze

  def brl(value)
    number_to_currency(value || 0)
  end

  def flash_class(type)
    FLASH_CLASSES.fetch(type.to_s, "msg-aviso")
  end

  # Ordem: foto enviada pelo administrador, foto que veio com o sistema, ilustração na cor da cobertura.
  def cupcake_image_tag(cupcake, **options)
    image_tag cupcake_image_source(cupcake), **options
  end

  def cupcake_image_source(cupcake)
    if cupcake.uploaded_photo?
      cupcake_photo_path(cupcake, v: cupcake.photo_updated_at.to_i)
    elsif Rails.application.assets.load_path.find(cupcake.photo_asset)
      cupcake.photo_asset
    else
      cupcake_image_path(cupcake, format: :svg)
    end
  end

  # Rótulo de campo obrigatório: asterisco vermelho, lido como "obrigatório" pelo leitor de tela.
  def required_label(form, field, text)
    form.label field do
      safe_join([ text, " ", tag.abbr("*", title: "obrigatório", class: "obrigatorio") ])
    end
  end

  def required_fields_legend
    tag.p(safe_join([ tag.abbr("*", title: "obrigatório", class: "obrigatorio"), " Campos obrigatórios" ]), class: "ajuda legenda-obrigatorio")
  end

  # Link da barra inferior (celular), marcado como ativo na seção atual.
  def tab_link(icon, label, path, active: current_page?(path))
    link_to path, class: ("ativo" if active) do
      tag.span(icon) + label
    end
  end
end
