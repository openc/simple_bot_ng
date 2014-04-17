#!/usr/bin/env ruby
# encoding: UTF-8
require 'mechanize'
require 'json'

# This method should return an Enumerable of Records. It must be defined.
def convert
  agent = Mechanize.new
  data = agent.get("http://dataset1:8080/runs/bm_insurance_licenses_raw/latest").body
  JSON.parse(data).each do |s|
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
    puts JSON.dump(d).strip
  end
end

convert
