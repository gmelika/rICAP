#!/usr/bin/env ruby

require 'socket'
require_relative 'messages/ICAPRequestHeader'
require_relative 'messages/ICAPRequestRESPMOD'
require_relative 'messages/ICAPResponseOptions'
require_relative 'messages/ICAPResponseContinue'
require_relative 'messages/ICAPResponseRESPMOD'

class ICAPServer
    def initialize
        @serverSocket = TCPServer.new 1344
    end

    def send_string(sock, str)
puts "sending #{str.length} bytes"
        begin
            while str != nil && str.size > 0
                sent = sock.send(str, 0)
puts "sent #{sent}"
                str = str[sent..-1]
            end
        rescue Exception => e #IOError, SocketError, SystemCallError
        # eof = true
            puts "SendError: #{ e } (#{ e.class })"
        end
    end
    def get_entity(clientSocket, entity_name, requestRESPMOD)
        entity_content = []
        loop do
            rcvline = clientSocket.gets
            entity_content << rcvline
            break if ((rcvline =~ /^\r\n$/) && (entity_content[-2] =~ /\r\n$/))
        end
        requestRESPMOD.add_entity(entity_name, entity_content)  
    end

    def start
        begin
        puts "Starting..."
        loop do
            Thread.start(@serverSocket.accept) do |clientSocket|
                loop do
                    requestHeader = ICAPRequestHeader.new

                    loop do
                        rcvline = clientSocket.gets
                        requestHeader.content_addline(rcvline)
                        break if ((rcvline =~ /^\r\n$/) && (requestHeader.content[-2] =~ /\r\n$/))
                    end

                    if requestHeader.type == :OPTIONS
                        puts "-> SENDING OPTIONS RESPONSE"
                        clientSocket.puts ICAPResponseOptions.new.render
                        puts "-> SENT OPTIONS RESPONSE"

                    elsif requestHeader.type == :RESPMOD
                        requestRESPMOD = ICAPRequestRESPMOD.new (requestHeader)
                        requestRESPMOD.entities_to_get.each do |entity_name|
                            get_entity(clientSocket, entity_name, requestRESPMOD)
                        end
                        if requestRESPMOD.need100continue?
                            puts "-> NEED 100"
                            clientSocket.puts ICAPResponseContinue.new.render
                            puts "-> SENT 100"
                            get_entity(clientSocket, "res-body", requestRESPMOD)
                            puts "-> RECEIVED DATA"
                            requestRESPMOD.remove_resbody_chunk_size
                            puts "-> REMOVED RESBODY CHUNK SIZE"
                        end

                        puts "-> CREATING ICAPResponseRESPMOD"
                        responseRESPMOD = ICAPResponseRESPMOD.new(requestRESPMOD)
                        puts "-> CREATED ICAPResponseRESPMOD"
                        send_string(clientSocket, responseRESPMOD.render)
                    elsif requestHeader.type == :REQMOD
                        puts :REQMOD

                    else
                        puts :UNKNOWN
                    end
                end
            end
        end
rescue Exception => e
      # Displays Error Message
      puts "Error: #{ e } (#{ e.class })"
    ensure
#      clientSocket.close
      puts "ensure: Closing"
    end
    end
end

s = ICAPServer.new
s.start

