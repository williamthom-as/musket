# frozen_string_literal: true

require "socket"
require "musket/connection"

module Musket

  class Main

    def initialize(local_addr, remote_addr)
      @local_addr = local_addr
      @remote_addr = remote_addr
    end

    def start
      puts "Service starting, listening on #{@local_addr}"

      local_host, local_port = @local_addr.split(":")
      local_serv = Musket::Server.new(local_host, local_port)

      Thread.abort_on_exception = true
      Thread.new { loop { sleep 1 } }

      loop do
        # whenever server.accept returns a new connection, start
        # a handler thread for that connection

        local_serv.with_connection do |local_server|
          Thread.start(local_server.accept) { |local| connection_thread(local) }
        end
      end

    end

    private

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def connection_thread(local)
      block_sz = 1024
      port, name = local.peeraddr[1..2]
      puts "*** Receiving data from #{name}:#{port}"

      remote_host, remote_port = @remote_addr.split(":")
      remote_server = Musket::Socket.new(remote_host, remote_port)

      # start reading from both ends
      remote_server.with_connection do |remote|
        loop do
          ready = IO.select([local, remote])

          if ready[0].include? local
            result = handle_transfer(local, remote, block_sz)
            break unless result
          end

          if ready[0].include? remote
            result = handle_transfer(remote, local, block_sz)
            break unless result
          end

        end

        local.close
        remote.close
      end

      puts "Finished receiving data from #{name}:#{port}"
    end

    def handle_transfer(conn_a, conn_b, block_sz=1024)
      data = conn_a.recv(block_sz)

      if data.empty?
        puts "Returning false, closed connection"
        return false
      end

      puts "Writing data to conn_b"
      conn_b.write(data)

      true
    end
  end

end

mm = Musket::Main.new("localhost:4000", "localhost:5432")
mm.start