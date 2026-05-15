class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def new
  end

  def create
    email = params[:email].to_s.strip
    password = params[:password].to_s

    if valid_admin_credentials?(email, password)
      start_session(email)
      redirect_to admin_root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    end_session
    redirect_to new_session_path, notice: "Signed out."
  end

  private

  def valid_admin_credentials?(email, password)
    expected_email = Rails.application.credentials.dig(:admin, :email) || ENV["ADMIN_EMAIL"]
    expected_password = Rails.application.credentials.dig(:admin, :password) || ENV["ADMIN_PASSWORD"]

    return false if expected_email.blank? || expected_password.blank?

    ActiveSupport::SecurityUtils.secure_compare(email.downcase, expected_email.to_s.downcase) &&
      ActiveSupport::SecurityUtils.secure_compare(password, expected_password.to_s)
  end
end
