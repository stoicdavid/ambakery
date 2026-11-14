class DailyProductionReportJob < ApplicationJob
  def perform = ProductionReportMailer.daily(Date.tomorrow).deliver_now
end