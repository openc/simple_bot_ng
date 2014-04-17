#!/usr/bin/env ruby
require 'json'
require 'mechanize'
require 'optparse'
require 'open3'

HOST = "http://dataset1:8080"

def dir(file)
  File.dirname(file)
end

def register(config)
  # Post manifest to server
  agent = Mechanize.new
  data = open(config, "r").read()
  registry = open("registry.js", "w")
  result = JSON.parse(
    agent.post("#{HOST}/runs/register", data).body)
  JSON.parse(data).each do |r|
    result[r["bot_id"]]["path"] = dir(config)
  end
  registry.write(JSON.dump(result))
  puts "registered."
  # Record result in local file
end

def complete(bot_name)
  # Post manifest to server
  agent = Mechanize.new
  runstate = JSON.load(open("registry.js", "r").read())[bot_name]
  result = agent.post("#{HOST}#{runstate['endpoint']}/finish", data)
  statefile.write(result.body)
  puts "completed."
  # Record result in local file
end

# Need the path to the binary...
def run(bot_name)
  registry = JSON.load(open("registry.js", "r").read())[bot_name]
  if !registry
    puts "Don't know anything about bot #{bot_name}; do you need to register it?"
    exit 1
  else
    cmd = "#{registry["path"]}/#{registry["executable"]}"
    options = {}
    command_output_each_line(cmd, options) do |line|
      print line
    end
  end
end

def send_data(bot_name)
  agent = Mechanize.new

  registry = JSON.load(open("registry.js", "r").read())
  if !registry[bot_name]
    puts "Don't know anything about bot #{bot_name}; do you need to register it?"
    exit 1
  else
    run = registry[bot_name]['endpoint'].split("/")[-1]
    puts "Sending data (run ##{run})..."
    cmd = "#{registry[bot_name]["path"]}/#{registry[bot_name]["executable"]}"
    options = {}
    count = 0
    command_output_each_line(cmd, options) do |line|
      url = "#{HOST}#{registry[bot_name]['endpoint']}"
      print "."
      result = JSON.parse(agent.post(url, line).body)
      open("registry.js", "w") do |f|
        registry[bot_name].update(result)
        f.write(JSON.dump(registry))
        count += result["last_submission_count"] || 0
      end
    end
  end
  puts "#{count} records sent!"
  puts "View your data at: #{HOST}#{registry[bot_name]['endpoint']}"
end

def runstate(bot_name)
  begin
    puts JSON.dump(JSON.load(open("registry.js", "r").read())[bot_name])
  rescue Errno::ENOENT
    puts "{}"
  end
end

def list
  puts "Registered bots:"
  printf("%-30s %s\n", "# Name", "# Status")
  begin
    bots = JSON.load(open("registry.js", "r").read())
    bots.each do |b, data|
      printf("%-30s %s\n", b, data['status'])
    end
  rescue Errno::ENOENT
    puts "No bots registered"
  end
end

def submit(bot_name)
  agent = Mechanize.new
  data = '{"submit": "true"}'
  registry = JSON.load(open("registry.js", "r").read())
  result = agent.post("#{HOST}#{registry[bot_name]['endpoint']}", data)
  open("registry.js", "w") do |f|
    registry[bot_name].update(JSON.parse(result.body))
    f.write(JSON.dump(registry))
  end
  puts "submitted"
end

# Consider moving to a separate library
def command_output_each_line(command, options)
  Open3::popen3(command, options) do |_, stdout, stderr, wait_thread|
    loop do
      check_output_with_timeout(stdout)

      begin
        yield stdout.readline
      rescue EOFError
        break
      end
    end
    status = wait_thread.value.exitstatus
    if status > 0
      message = "Bot <#{command}> exited with status #{status}: #{stderr.read}"
      raise RuntimeError.new(message)
    end
  end
end

def check_output_with_timeout(stdout, initial_interval = 10, timeout = 3600)
  interval = initial_interval
  loop do
    reads, _, _ = IO.select([stdout], [], [], interval)
    break if !reads.nil?
    raise "Timeout! - could not read from external bot after #{timeout} seconds" if reads.nil? && interval > timeout
    interval *= 2
  end
end

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{ARGV[0]} [options] [register|submit|run|runstate] [bot_name]"
  opts.on("-c", "--config CONFIG", "Path to config file (required)") do |v|
    options[:config] = v
  end
end
optparse.parse!

bot_name = ARGV[1]
operation = ARGV[0]

if (!options[:config] && operation == "register")
  puts optparse
  exit 1
end

bot_name_required = ["runstate", "submit", "run"]
if bot_name_required.include?(operation) && !bot_name
  puts optparse
  exit 1
end
case operation
when "register"
  register(options[:config])
when "submit"
  submit(bot_name)
when "send"
  send_data(bot_name)
when "run"
  run(bot_name)
when "runstate"
  runstate(bot_name)
when "list"
  list
else

  puts "don't know what to do with #{operation}"
end
