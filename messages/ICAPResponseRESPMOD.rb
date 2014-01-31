#!/usr/bin/env ruby

class ICAPResponseRESPMOD
  def initialize(requestRESPMOD)
    @requestRESPMOD = requestRESPMOD
    @header = []
    @header << "ICAP/1.0 200 OK"
    @header << "Server: rICAP 0.1"
    @header << "Connection: close"
    @header << "ISTag: \"1234567890\""
    @entities = {}
    if @requestRESPMOD.entities.key?("res-body")
      @entities["res-body"] = []
      @entities["res-body"] << requestRESPMOD.entities["res-body"].size.to_s(16)
      @entities["res-body"] << requestRESPMOD.entities["res-body"]
      @entities["res-body"] << "0\r\n\r\n"
    end
    if requestRESPMOD.entities.key?("res-hdr")
      @entities["res-hdr"] = []
      @entities["res-hdr"] << requestRESPMOD.entities["res-hdr"].join()
    end
    if requestRESPMOD.entities.key?("req-hdr")
      
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
    message << @header.join("\r\n")
    
    message << @entities["res-hdr"].join()
    message << @entities["res-body"].join("\r\n")
    
    puts "==================================== START RESPMOD ===================================================="
    return message.join()
    puts "==================================== STOP RESPMOD ===================================================="
  end
  
end