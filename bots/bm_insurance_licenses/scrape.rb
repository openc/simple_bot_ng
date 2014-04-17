#!/usr/bin/env ruby
# encoding: UTF-8
require 'mechanize'
require 'json'

# This method should return an Enumerable of Records. It must be defined.
def fetch_all_records(opts={})
  agent = Mechanize.new

  # Set up counter. Incrementers can restart where they left off.
  index_page = agent.get(
    "http://www.bma.bm/licensed-enities-insurance/licensed-entities.asp")
  doc = Nokogiri::HTML(index_page.body)
  last_item = doc.xpath("//div[@class='c1Content']//li").count - 1
  current_state = JSON.parse(`./turbot.rb runstate bm_insurance_licenses_raw`)
  current_state = 0
  count = 0
  (current_state..last_item).each do |num|
    licence_url = "http://www.bma.bm/licensed-enities-insurance/licensed-entities-detail.asp?line=#{num}"
    page = agent.get(licence_url)
    doc = Nokogiri::HTML(page.body)
    fields = doc.xpath("//table/tr/td[2]")
    name, address, licence_class, comment = fields.map(&:content)
    puts JSON.dump({
      :name => name,
      :address => address,
      :licence_class => licence_class,
      :comment => comment,
      :licence_url => licence_url,
      :last_updated_at => Time.now.iso8601(2)})
    count += 1
    break if count > 10
  end
end

fetch_all_records
