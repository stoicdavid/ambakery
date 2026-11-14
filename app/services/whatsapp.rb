module Whatsapp
  TEST_CONFIG = {
    api_version: "v27.0", phone_number_id: "PHONE_ID", business_account_id: "WABA_ID",
    access_token: "test-token", app_secret: "test-secret", verify_token: "test-verify"
  }.freeze

  def self.config
    Rails.env.test? ? TEST_CONFIG : Rails.application.credentials.whatsapp
  end
end