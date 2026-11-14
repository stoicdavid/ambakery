class Admin::DashboardController < ApplicationController
  # The Authentication concern already requires login by default.
  # Just make sure there's no `allow_unauthenticated_access` here.
  def index; end
end