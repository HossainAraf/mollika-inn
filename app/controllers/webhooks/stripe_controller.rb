module Webhooks
  class StripeController < ActionController::API
    def receive
      render json: { received: true }, status: :ok
    end
  end
end
