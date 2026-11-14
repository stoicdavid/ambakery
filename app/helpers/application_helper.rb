module ApplicationHelper
  def mxn(cents) = number_to_currency(cents / 100.0, unit: "$", format: "%u%n MXN")
end
