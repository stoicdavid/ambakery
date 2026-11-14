class ProductionReportMailerPreview < ActionMailer::Preview
  def daily = ProductionReportMailer.daily(Date.tomorrow)
end
