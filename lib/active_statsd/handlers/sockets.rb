# frozen_string_literal: true

module ActiveStatsD
  # Socket handling functionality for the StatsD server.
  module SocketHandler
    def create_and_bind_socket
      socket = UDPSocket.new(Socket::AF_INET)
      socket.bind(@host, @port)
      socket
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Socket bind error: #{e.class} - #{e.message}"
      nil
    end

    def configure_socket_buffer(socket)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVBUF, 2**20)
    rescue StandardError => e
      Rails.logger.warn "[ActiveStatsD] Could not set SO_RCVBUF: #{e.message}"
    end

    def listen_for_messages(socket)
      until @shutdown.true?
        next unless socket.wait_readable(1)

        process_socket_message(socket)
      end
    end

    def process_socket_message(socket)
      data, _peer = socket.recvfrom_nonblock(4096)
      handle_message(data.strip)
    rescue IO::WaitReadable
      # Continue to next iteration
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Listener error: #{e.class} - #{e.message}"
    end
  end
end
