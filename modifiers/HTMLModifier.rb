#!/usr/bin/env ruby

require 'nokogiri'

class HTMLModifier
    def initialize(html, charset = 'UTF-8')
        @htmlText = html
        @charset = charset
        @html = Nokogiri::HTML(@htmlText) do |config|
            config.nonet
        end
        @isHTML = @html.search('html').count > 0
    end

    def run
        if !@isHTML
            return @htmlText
        end
        @html.css('.advertisement').remove
        result = @html.to_html
        return result
    end

end