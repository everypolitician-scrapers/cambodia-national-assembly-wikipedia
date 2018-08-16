#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    member_rows.map { |row| fragment(row => MemberRow).to_h }
  end

  private

  def member_tables
    noko.xpath('//span[@id="Members"]//following::table[.//th[contains(.,"MP")]]')
  end

  def member_rows
    member_tables.xpath('.//tr[td[2]]')
  end
end

class MemberRow < Scraped::HTML
  field :id do
    tds[1].css('a/@wikidata').map(&:text).first
  end

  field :name do
    tds[1].text.tidy
  end

  field :party do
    tds[2].text.tidy
  end

  field :party_id do
    tds[2].css('a/@wikidata').map(&:text).first
  end

  field :area do
    noko.xpath('preceding::h3/span[@class="mw-headline"]').last.text
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_MPs_of_the_National_Assembly_of_Cambodia'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party area])
