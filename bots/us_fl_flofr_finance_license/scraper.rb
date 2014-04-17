#!/usr/bin/env ruby
# encoding: UTF-8

# you may need to require other libraries here
require 'nokogiri'
require 'mechanize'


class String
  def strip
    self.gsub(/\u00A0|^\s+|\s+$/,'')
  end
end

class NilClass
  def strip
    self
  end
end

def tmpdir
  dir = "#{File.dirname(__FILE__)}/tmp"
  FileUtils.mkdir_p(dir)
  dir
end

class UsFlFlofrFinanceLicense

  URL = "https://real.flofr.com/ConsumerServices/FinancialInstitutions/InstSrch.aspx"

  ## Extend method for extracting text from a single Nokogiri Node
  def s_text(node)
    return node.text.strip
  end

  ## Extend method for extracting text from a particular tree of Nokogiri Node(s)
  def a_text(node)
    ret = []
    if node.kind_of? (Nokogiri::XML::Element)
      tmp = []
      node.children().each{|nd|
        tmp << a_text(nd)
      }
      ret << tmp
    elsif node.kind_of? (Nokogiri::XML::NodeSet)
      node.collect().each{|nd|
        ret << a_text(nd)
      }
    elsif node.kind_of? (Nokogiri::XML::Text)
      ret << s_text(node)
    else
      #raise "Invalid element found while processing innert text #{node}"
    end
    return ret.flatten
  end

  def attributes(node,attr)
    return (node.nil? or node.first.nil? or node.first.attributes.nil? or node.first.attributes[attr].nil?) ? "" : node.first.attributes[attr].value
  end

  def normalise(text)
    # Replace whitespace with single space, and strip leading/trailing spaces.
    normalise_utf8_spaces(text).strip
  end

  def normalise_utf8_spaces(raw_text)
    raw_text&&raw_text.gsub(/\xC2\xA0/, ' ')
  end

  def get_column_name(heading_text)
    # Compute the database column name from the text of a table heading.  A
    # hash lookup may be better here.
    return (heading_text.nil? or heading_text.empty?)? heading_text : normalise(heading_text).downcase.gsub(/#|no\./, 'number').gsub(',','').gsub(' ', '_').gsub('/','_or_').to_sym
  end

  def get_column_names(headings)
    return headings.collect{|heading| get_column_name(heading)}
  end

  def init(br,status)
    return br.get("https://real.flofr.com/ConsumerServices/FinancialInstitutions/InstResults.aspx?Status=#{status}")
  end

  # This method should return an array of Records. It must be defined.
  def fetch_all_records(opts = {})
    # Here we are iterating over an array. Normally you would scrape
    # things from a website and construct LicenceRecords from that.
    #
    br = Mechanize.new { |b|
      b.user_agent_alias = 'Linux Firefox'
      b.read_timeout = 1200
      b.max_history=0
      b.retry_change_requests = true
      b.verify_mode = OpenSSL::SSL::VERIFY_NONE
    }
    records = []
    status_pair = ["01","02"]
    status_pair.each{|status|
      pgno = 1
      begin
        page = (pgno == 1)? init(br,status) : (page.form_with(:id=>"aspnetForm") do |f|
          f['__EVENTTARGET'] = "ctl00$Main$gvResults"
          f['__EVENTARGUMENT'] = "Page$#{pgno}"
          page = f.submit
        end
        page
                                     )
        IO.write("#{tmpdir}/tmp_details#{pgno}.html",page.body)
        list = parse(page,"List By HTML",{:reporting_date=>Time.now.iso8601(2),:last_updated_at => Time.now.iso8601(2),:source_url => page.uri.to_s})
        list.each{|datum|
          puts JSON.dump(datum)
        }
        break if list.nil? or list.empty? or list.length < 10
        pgno = pgno + 1
      end while(true)
    }
  end

  def parse(page,action,arg)
    if action == "List By HTML"
      data = page.body rescue page
      records,doc = [],Nokogiri::HTML(data)
      IO.write("#{tmpdir}/tmp_list.html",data)
      keys = get_column_names(a_text(doc.xpath(".//table[@id='ctl00_Main_gvResults']/tr[position()=1]")).delete_if{|item| item.nil? or item.empty?})
      raise "Unhandle case of column headers, was expecting 14 found #{keys.length}" if keys.length != 14 unless keys.length == 0
      doc.xpath(".//table[@id='ctl00_Main_gvResults']/tr[position()>1 and position()<last()]").each{|tr|
        values = tr.search('td').map{|td| a_text(td).join("\n").strip }
        datum = Hash[keys.zip(values)]
        datum[:contact_info] = datum[:contact_info].gsub(/\s{2,}/,' ') unless datum[:contact_info].nil?
        datum[:address] = datum[:address].gsub(/\s{2,}/,' ') unless datum[:address].nil?
        datum[:date_opened] = Time.strptime(datum[:date_opened],'%m/%d/%Y').iso8601(2) unless datum[:date_opened].nil? or datum[:date_opened].empty?
        datum[:type] = datum[:type]

        records << datum.merge(arg)
      }
      return records
    end
  end
end

UsFlFlofrFinanceLicense.new.fetch_all_records
