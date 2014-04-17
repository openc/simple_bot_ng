#!/usr/bin/env ruby
# encoding: UTF-8
require 'mechanize'
require 'json'

# This method should return an Enumerable of Records. It must be defined.
def convert
  agent = Mechanize.new
  data = agent.get("http://dataset1:8080/runs/bm_insurance_licenses_raw/latest").body
  print "["
  count = 0
  JSON.parse(data).each do |s|
    print "," if count > 0
    d = {
      sample_date: s["last_updated_at"],
      company: {
        name: s["name"],
        jurisdiction: "bm"
      },
      source_url: s["licence_url"],
      data: [{
        data_type: :licence,
        properties: {
          category: 'Financial',
          jurisdiction_code: "bm",
          jurisdiction_classification: "Insurance: #{s["licence_class"]}"
        }
      }]
    }
    print JSON.dump(d).strip
    count += 1
  end
  print "]"
end

convert
