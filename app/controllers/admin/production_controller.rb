class Admin::ProductionController < ApplicationController
  def show
    date = (Date.parse(params[:date]) rescue nil) || Date.tomorrow
    @report = ProductionReport.new(date)

    respond_to do |format|
      format.html
      format.csv { send_data @report.to_csv, filename: "produccion-#{date}.csv" }
    end
  end
end
