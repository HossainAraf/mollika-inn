module Guests
  class ProfilesController < ApplicationController
    skip_before_action :require_authentication
    before_action :require_guest_session

    def show
      @guest = current_guest
    end

    def edit
      @guest = current_guest
    end

    def update
      @guest = current_guest
      if @guest.update(profile_params)
        redirect_to guests_profile_path, notice: "Profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def require_guest_session
      redirect_to new_guests_session_path, alert: "Please sign in." unless current_guest
    end

    def profile_params
      params.require(:guest).permit(:first_name, :last_name, :phone, :address, :nationality)
    end
  end
end
