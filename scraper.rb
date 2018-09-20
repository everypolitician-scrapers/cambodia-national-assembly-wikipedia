#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'
require_relative 'lib/unspan_all_tables'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links
  decorator UnspanAllTables

  field :members do
    member_rows.map { |row| fragment(row => MemberRow).to_h }
  end

  private

  def member_tables
    noko.xpath('//span[@id="List_of_members"]//following::table[.//th[contains(.,"Members")]]')
  end

  def member_rows
    member_tables.xpath('.//tr[td[2]]')
  end
end

class MemberRow < Scraped::HTML
  PARTIES = { # TODO: scrape these
    '1E90FF' => { name: "Cambodian People's Party", id: 'Q769308' },
    '0047AB' => { name: 'Cambodia National Rescue Party', id: 'Q5025162' },
  }

  field :id do
    tds[3].css('a/@wikidata').map(&:text).first
  end

  field :name do
    tds[3].text.tidy
  end

  field :party do
    PARTIES[party_colour][:name]
  end

  field :party_id do
    PARTIES[party_colour][:id]
  end

  field :area do
    tds[0].text.tidy
  end

  field :area_id do
    tds[0].css('a/@wikidata').map(&:text).first
  end

  private

  def tds
    noko.css('td')
  end

  def party_colour
    tds[2].attr('style')[/background-color:#(\w+)/, 1]
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_members_of_the_National_Assembly_of_Cambodia,_2013%E2%80%9318'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party area])
