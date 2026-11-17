require "csv"

# US15: relatório de vendas por período (só pedidos entregues) e avaliações recentes (US10 CA#3).
class Admin::ReportsController < Admin::BaseController
  PERIODS = { "daily" => [ "Hoje", 0 ], "weekly" => [ "Últimos 7 dias", 6 ], "monthly" => [ "Últimos 30 dias", 29 ] }.freeze

  def show
    @period = params[:period].presence_in(PERIODS.keys) || "monthly"
    @to = parse_date(params[:to]) || Time.zone.today
    @from = parse_date(params[:from]) || @to - PERIODS.dig(@period, 1)
    @report = Order.sales_report(@from, @to)

    respond_to do |format|
      format.html { @reviews = Review.includes(:cupcake, :user).order(created_at: :desc).limit(20) }
      format.csv { send_data csv_report, filename: "vendas-#{@from}-#{@to}.csv", type: "text/csv; charset=utf-8" }
    end
  end

  private

  def parse_date(value)
    Date.iso8601(value) if value.present?
  rescue Date::Error
    flash.now[:error] = "Datas inválidas."
    nil
  end

  # Separador ";" e BOM para o Excel em português abrir com acentos e colunas certas.
  def csv_report
    money = ->(value) { format("%.2f", value).tr(".", ",") }
    "﻿" + CSV.generate(col_sep: ";") do |csv|
      csv << [ "Relatório de vendas", "#{l @from} a #{l @to}" ]
      csv << [ "Pedidos concluídos", @report[:orders_count] ]
      csv << [ "Total vendido", money.call(@report[:total]) ]
      csv << []
      csv << %w[Sabor Quantidade Valor]
      @report[:best_sellers].each { |name, quantity, amount| csv << [ name, quantity, money.call(amount) ] }
    end
  end
end
