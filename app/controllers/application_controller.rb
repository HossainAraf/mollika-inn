class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_guest

  private

  def current_guest
    @current_guest ||= Guest.find_by(id: session[:guest_id]) if session[:guest_id]
  end
end
