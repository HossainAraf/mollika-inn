module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  private

  def authenticated?
    session[:admin_authenticated] == true
  end

  def require_authentication
    redirect_to new_session_path, alert: "Please sign in first." unless authenticated?
  end

  def start_session(email)
    reset_session
    session[:admin_authenticated] = true
    session[:admin_email] = email
  end

  def end_session
    reset_session
  end
end
