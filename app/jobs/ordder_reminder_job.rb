class OrderReminderJob < ApplicationJob
  def perform
    Order.committed.channel_whatsapp.where(scheduled_on: Date.tomorrow).find_each do |order|
      OrderNotificationJob.perform_later(order, "reminder")   # a string, since jobs can't receive lambdas
    end
  end
end