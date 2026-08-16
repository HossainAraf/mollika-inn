class HealthController < ApplicationController
  def smtp_test
    require "socket"

    host = ENV.fetch("SMTP_ADDRESS")
    port = ENV.fetch("SMTP_PORT", 587).to_i

    socket = TCPSocket.new(host, port)

    render plain: "SMTP TCP connection SUCCESS: #{host}:#{port}"
    socket.close
  rescue => e
    render plain: "SMTP TCP connection FAILED: #{e.class} - #{e.message}", status: 500
  end
end
