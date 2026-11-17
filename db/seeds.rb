# Dados de demonstração. Pode rodar mais de uma vez: só insere o que ainda não existe.
demo_password = ENV.fetch("DEMO_PASSWORD", "cupcake123")

categories = [
  [ "Chocolate", "chocolate" ], [ "Frutas", "frutas" ], [ "Clássicos", "classicos" ],
  [ "Diet", "diet" ], [ "Sem Glúten", "sem-gluten" ], [ "Sazonais", "sazonais" ]
].to_h { |name, slug| [ slug, Category.find_or_create_by!(slug: slug) { |c| c.name = name } ] }

[
  # nome, categoria, preço, estoque, cor, calorias, gordura, açúcar, alérgenos, descrição, ingredientes
  [ "Chocolate Clássico", "chocolate", "9.90", 30, "#6b3e26", 320, "16.0", "28.0", "Glúten, Lactose, Ovo",
    "Massa de chocolate 50% cacau com ganache cremosa.", "Farinha de trigo, cacau, ovos, leite, manteiga, açúcar" ],
  [ "Brigadeiro Gourmet", "chocolate", "10.90", 25, "#4a2c1d", 350, "17.5", "32.0", "Glúten, Lactose, Ovo",
    "Recheio e cobertura de brigadeiro com granulado belga.", "Farinha de trigo, cacau, leite condensado, chocolate belga" ],
  [ "Red Velvet", "classicos", "11.50", 20, "#b91c1c", 330, "15.0", "30.0", "Glúten, Lactose, Ovo",
    "Massa aveludada vermelha com cobertura de cream cheese.", "Farinha de trigo, cacau, buttermilk, cream cheese" ],
  [ "Baunilha dos Sonhos", "classicos", "8.90", 30, "#fde68a", 290, "13.0", "27.0", "Glúten, Lactose, Ovo",
    "Massa de baunilha com buttercream suave.", "Farinha de trigo, fava de baunilha, manteiga, ovos" ],
  [ "Caramelo Salgado", "classicos", "11.90", 4, "#d97706", 340, "16.5", "31.0", "Glúten, Lactose, Ovo",
    "Recheio de caramelo com flor de sal.", "Farinha de trigo, açúcar mascavo, creme de leite, flor de sal" ],
  [ "Morango com Chantilly", "frutas", "10.50", 18, "#f472b6", 280, "12.0", "26.0", "Glúten, Lactose, Ovo",
    "Massa leve com morangos frescos e chantilly.", "Farinha de trigo, morango, creme de leite, ovos" ],
  [ "Limão Siciliano", "frutas", "9.90", 15, "#fef08a", 270, "11.5", "24.0", "Glúten, Lactose, Ovo",
    "Massa cítrica com curd de limão e merengue maçaricado.", "Farinha de trigo, limão siciliano, ovos, manteiga" ],
  [ "Cacau Fit", "diet", "12.90", 12, "#78350f", 190, "8.0", "6.0", "Ovo, Oleaginosas",
    "Adoçado com xilitol, massa de farinha de amêndoas.", "Farinha de amêndoas, cacau, xilitol, ovos" ],
  [ "Coco sem Glúten", "sem-gluten", "11.90", 10, "#f5f5f4", 260, "14.0", "20.0", "Lactose, Ovo",
    "Massa de farinha de arroz com coco fresco.", "Farinha de arroz, coco ralado, leite, ovos" ],
  [ "Abóbora com Especiarias", "sazonais", "12.50", 8, "#ea580c", 300, "13.0", "25.0", "Glúten, Lactose, Ovo",
    "Edição de outono com canela, cravo e noz-moscada.", "Farinha de trigo, abóbora, canela, cravo, noz-moscada" ]
].each do |name, slug, price, stock, color, calories, fat, sugar, allergens, description, ingredients|
  Cupcake.find_or_create_by!(name: name) do |c|
    c.assign_attributes(category: categories.fetch(slug), price: price, stock: stock, color: color, calories: calories,
                        fat_grams: fat, sugar_grams: sugar, allergens: allergens, description: description,
                        ingredients: ingredients, min_stock: 5)
  end
end

[ [ "Centro", "5.00", 30 ], [ "Bairros próximos (até 5 km)", "8.00", 45 ], [ "Bairros distantes (5 a 10 km)", "12.00", 60 ] ].each do |name, fee, eta|
  DeliveryZone.find_or_create_by!(name: name) { |z| z.assign_attributes(fee: fee, eta_minutes: eta) }
end

Coupon.find_or_create_by!(code: "BEMVINDO10") do |c|
  c.assign_attributes(description: "10% na primeira compra", percentage: 10, valid_until: 1.year.from_now.to_date, usage_limit: 500)
end
Coupon.find_or_create_by!(code: "VERAO2025") do |c|
  c.assign_attributes(description: "Promoção encerrada", percentage: 20, valid_until: Date.new(2025, 3, 20))
end

[
  [ "Administrador da Loja", "admin@sweetindulgence.com", :admin, "83999990000" ],
  [ "Carlos Entregador", "entregador@sweetindulgence.com", :courier, "83999991111" ],
  [ "Cliente Demonstração", "cliente@sweetindulgence.com", :customer, "83999992222" ]
].each do |name, email, role, phone|
  User.find_or_create_by!(email: email) do |u|
    u.assign_attributes(name: name, role: role, phone: phone, password: demo_password)
  end
end

puts "Dados de demonstração prontos: #{Cupcake.count} cupcakes, #{User.count} usuários."
