class PasswordsController < ApplicationController
  skip_before_action :require_authentication

  def new
  end

  def create
    redirect_to new_session_path, notice: "Password reset is not enabled yet. Contact admin."
  end

  def edit
    redirect_to new_session_path, alert: "Password reset token is invalid."
  end

  def update
    redirect_to new_session_path, notice: "Password updated."
  end
end
