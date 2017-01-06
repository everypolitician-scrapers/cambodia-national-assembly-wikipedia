#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"MP")]]//tr[td]')
  raise 'No rows' if rows.count.zero?
  rows.each do |tr|
    td = tr.css('td')
    data = {
      name:           td[1].text.tidy,
      wikiname:       td[1].xpath('.//a[not(@class="new")]/@title').text,
      party:          td[2].text.tidy,
      party_wikiname: td[2].xpath('.//a[not(@class="new")]/@title').text,
      area:           td[1].xpath('preceding::h3/span[@class="mw-headline"]').last.text,
      term:           5,
      source:         url,
    }
    ScraperWiki.save_sqlite(%i(name area party term), data)
  end
end

scrape_list('https://en.wikipedia.org/wiki/List_of_MPs_of_the_National_Assembly_of_Cambodia')
