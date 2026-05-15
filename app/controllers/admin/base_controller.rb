class Admin::BaseController < ApplicationController
  before_action :require_admin!

  layout "admin"

  private

  def require_admin!
    unless authenticated?
      redirect_to new_session_path, alert: "Please sign in to access the admin panel."
    end
  end
end
