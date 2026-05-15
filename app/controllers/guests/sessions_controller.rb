module Guests
  class SessionsController < ApplicationController
    skip_before_action :require_authentication

    def new
    end

    def create
      guest = Guest.find_by(email: params[:email].to_s.downcase)

      if guest.present?
        session[:guest_id] = guest.id
        redirect_to guests_profile_path, notice: "Signed in successfully."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:guest_id)
      redirect_to root_path, notice: "Signed out."
    end
  end
end
