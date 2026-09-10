class ApplicationController < ActionController::Base
  include Authentication
  stale_when_importmap_changes

  helper_method :current_guest

  resque_from ActionController::InvalidAuthenticityToken do |e|
    Rails.logger.warn(
      "CSRF failure: #{request.method} #{request.fullpath} " \
      "session=#{session.id} referer=#{request.referer}"
    )
    redirect_to new_session_path, alert: "Session expired. Please sign in again."
  end

  private

  def current_guest
    @current_guest ||= Guest.find_by(id: session[:guest_id]) if session[:guest_id]
  end
end
