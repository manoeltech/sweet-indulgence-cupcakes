class Cupcake < ApplicationRecord
  # A mensagem padrão do belongs_to ("é obrigatório(a)") não diz qual campo falta.
  belongs_to :category, optional: true
  has_many :reviews, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error

  validates :category, presence: { message: "Escolha uma categoria." }
  validates :name, presence: { message: "Informe o nome do cupcake." }
  validates :description, presence: { message: "Informe a descrição." }
  validates :price, numericality: { greater_than: 0, message: "O preço precisa ser maior que zero." }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "O estoque não pode ser negativo." }
  validates :min_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "O estoque mínimo não pode ser negativo." }
  validates :calories, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "Calorias precisam ser um número inteiro." }, allow_nil: true
  validates :fat_grams, :sugar_grams, numericality: { greater_than_or_equal_to: 0, message: "Informações nutricionais precisam ser números." }, allow_nil: true
  validates :color, format: { with: /\A#\h{6}\z/, message: "Cor inválida." }

  # O administrador digita "12,50": vírgula decimal vira ponto antes de converter.
  %i[price fat_grams sugar_grams].each do |attribute|
    define_method(:"#{attribute}=") { |value| super(value.is_a?(String) ? value.strip.tr(",", ".") : value) }
  end

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock > 0") }

  # US01 RN#1: só aparecem cupcakes ativos e com estoque. US02: filtro por categoria.
  def self.storefront(category_slug: nil, query: nil)
    scope = active.in_stock.includes(:category)
    scope = scope.joins(:category).where(categories: { slug: category_slug }) if category_slug.present?
    scope = scope.where("cupcakes.name ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
    scope.order(:name)
  end

  # US12 CA#3: alerta de estoque baixo para o administrador.
  def self.low_stock
    active.where("stock <= min_stock").order(:stock)
  end

  # Foto real do sabor, se existir em app/assets/images/cupcakes/ (créditos em docs/creditos-das-fotos.md).
  def photo_asset
    "cupcakes/#{name.parameterize}.jpg"
  end

  def allergen_list
    allergens.split(",").map(&:strip).reject(&:blank?)
  end

  def average_rating
    reviews.average(:rating)&.round(1)
  end

  def low_stock?
    stock <= min_stock
  end

  def adjust_stock!(delta)
    raise BusinessRuleError, "Estoque insuficiente de #{name}." if stock + delta < 0

    update!(stock: stock + delta)
  end

  # US11 / CU02 passo 5: o cupcake sai do cardápio, mas continua no histórico de pedidos.
  def remove_from_menu!(confirmation)
    raise BusinessRuleError, "Remoção cancelada: digite o nome exato do cupcake para confirmar." unless confirmation == name

    update!(active: false)
  end
end
