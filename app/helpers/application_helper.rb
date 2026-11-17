module ApplicationHelper
  FLASH_CLASSES = { "success" => "msg-sucesso", "error" => "msg-erro", "warning" => "msg-aviso", "notice" => "msg-sucesso", "alert" => "msg-erro" }.freeze

  def brl(value)
    number_to_currency(value || 0)
  end

  def flash_class(type)
    FLASH_CLASSES.fetch(type.to_s, "msg-aviso")
  end

  # Link da barra inferior (celular), marcado como ativo na seção atual.
  def tab_link(icon, label, path, active: current_page?(path))
    link_to path, class: ("ativo" if active) do
      tag.span(icon) + label
    end
  end
end
