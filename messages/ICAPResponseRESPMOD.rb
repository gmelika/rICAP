#!/usr/bin/env ruby
require_relative '../modifiers/HTMLModifier'

class ICAPResponseRESPMOD
    def initialize(requestRESPMOD)
        @requestRESPMOD = requestRESPMOD
        @header = []
        @header << "ICAP/1.0 200 OK"
        @header << "Server: rICAP 0.1"
        @header << "Connection: close"
        @header << "ISTag: \"1234567890\""
        @entities = {}
        @contentType = nil
puts 'headers initialized'
        if requestRESPMOD.entities.key?("res-hdr")
            @entities["res-hdr"] = []
            @entities["res-hdr"] << requestRESPMOD.entities["res-hdr"].join()
        end
        if @requestRESPMOD.entities.key?("res-body")
            @entities["res-body"] = []
            body = requestRESPMOD.entities["res-body"]
            @bodyLength = body.size
            puts "body.length before = #{body.size}"
            if ( @entities["res-hdr"].join("\r\n") =~ /Content-Type:\s*text\/html(;\s*charset=(.*?)\r\n)?/mi )
                puts "is html"
                charset = $~[2]
                puts "charset = #{charset}"
                html = HTMLModifier.new(body, charset)
                body = html.run
                @bodyLength = body.size
                puts "body.length after = #{@bodyLength}"
            else
                puts "is NOT html"
            end
            @entities["res-body"] << body.size.to_s(16)
            @entities["res-body"] << body
            @entities["res-body"] << "0\r\n\r\n"
        end
    end

    def render
        header_offset = {}
        
        if @entities.key?("res-hdr")
            header_offset["res-hdr"] = 0
        end

        if @entities.key?("res-body")
            header_offset["res-body"] = @entities["res-hdr"].join.size
        end

        encapsulated = "Encapsulated: "
        encapsulated_array = []
        header_offset.each_pair do |k,v|
            encapsulated_array << "#{k}=#{v}"
        end
        encapsulated += encapsulated_array.join(", ")
        @header << encapsulated
        @header << "\r\n"

        message = []
        hdrs = @header.join("\r\n")
        hdrs = hdrs.gsub(/Content-Length:\s*\d+\r\n/mi, "Content-Length: #{@bodyLength}\r\n")
puts hdrs
        message << hdrs #@header.join("\r\n").gsub(/Content-Length:\s*\d+\r\n/mi, "Content-Length: #{@bodyLength}\r\n")

        message << @entities["res-hdr"].join()
        message << @entities["res-body"].join("\r\n")

        puts "==================================== START RESPMOD ===================================================="
        result = message.join()
        puts "==================================== STOP RESPMOD ===================================================="
        return result
    end

end
