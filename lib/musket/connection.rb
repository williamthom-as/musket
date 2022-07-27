# frozen_string_literal: true

require "socket"

module Musket

  class Connection

    # @return [String]
    attr_reader :host

    # @return [Integer]
    attr_reader :port

    def initialize(host, port)
      @host = host
      @port = port
    end

    def open_connection
      raise "Not here"
    end

    # @yield [Musket:Server]
    def with_connection(&block)
      return nil unless block_given?

      @conn ||= open_connection

      yield @conn
    end

    def reset
      @conn = nil
    end

    def to_s
      "#{@host}:#{@port}"
    end
  end

  class Server < Connection

    def open_connection
      TCPServer.open(@host, @port)
    end
  end

  class Socket < Connection

    def open_connection
      TCPSocket.new(@host, @port)
    end
  end

end

# def self.get_server(host, port)
#   TCPServer.open(host, port)
# end
#
# def self.get_socket(host, port)
#   TCPSocket.new(host, port)
# end
