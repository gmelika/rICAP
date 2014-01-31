#!/usr/bin/env ruby

require 'nokogiri'

class HTMLModifier
    def initialize(html, charset)
        @htmlText = html
        @charset = charset
        @html = Nokogiri::HTML(@htmlText, nil, @charset) do |config|
            config.nonet
        end
        @isHTML = @html.search('html').count > 0
    end

    def run
        if !@isHTML
            return @htmlText
        end
        @html.css('.advertisement').remove
        puts "==================================== START Modified HTML ===================================================="
        result = @html.to_html
        puts result
        puts "==================================== STOP Modified HTML ===================================================="
        return result
    end

end