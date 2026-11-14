# app/mailers/production_report_mailer.rb
class ProductionReportMailer < ApplicationMailer
  helper :application   # for mxn

  def daily(date = Date.tomorrow)
    @report = ProductionReport.new(date)
    attachments["produccion-#{date}.csv"] = @report.to_csv
    mail to: ENV.fetch("BAKERY_TEAM_EMAILS", "david.rodriguez@fietstech.com").split(","),
         subject: "Producción #{DeliveryDate.label_for(date)} · #{@report.orders.count} pedidos"
  end
end
