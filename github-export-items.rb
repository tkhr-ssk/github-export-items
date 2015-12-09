#!/usr/bin/env ruby
require 'octokit'

class String
  def csvenc
    str=self
    '"'+str.gsub(/"/,'""')+'"'
  end
end

commands = {
  "pulls" => {
    description: "Export Pull Requests(all)",
    get: ->(c,r){ c.pulls r, state: 'all' },
    header: "number,title,user,head,base",
    record: ->(i){ "#{i.number},\"#{i.title}\",\"#{i.user.login}\",\"#{i.head.ref}\",\"#{i.base.ref}\""}
  },
  "pulls_open" => {
    description: "Export Pull Requests(only opened)",
    get: ->(c,r){ c.pulls r, state: 'open' },
    header: "number,title,user,head,base",
    record: ->(i){ "#{i.number},\"#{i.title}\",\"#{i.user.login}\",\"#{i.head.ref}\",\"#{i.base.ref}\""}
  },
  "pull_requests_comments" => {
    description: "Export Review Comments",
    get: ->(c,r){ c.pull_requests_comments r },
    header: "id,pull,path,user,body,created_at,home_url",
    record: ->(i){ "#{i.id},\"#{i.pull_request_url[/\d+$/]}\",\"#{i.path}\",\"#{i.user.login}\",#{i.body.csvenc},\"#{i.created_at}\",\"#{i.html_url}\""}
  },
  "issues_comments" => {
    description: "Export Issues Comments",
    get: ->(c,r){ c.issues_comments r },
    header: "id,issue,user,body,created_at,home_url",
    record: ->(i){ "#{i.id},\"#{i.html_url[/\/(\d+)/][1]}\",\"#{i.user.login}\",#{i.body.csvenc},\"#{i.created_at}\",\"#{i.html_url}\""}
  }
}

$COMMANDS = commands

def usage
  puts <<-EOS
Usage:
  #{$0} <COMMAND> <GITHUB_REPOSITORY>

Commands:
EOS
  $COMMANDS.each{|k,v| printf "  %-24s %s\n", k,v[:description]} 
  puts <<-EOS

Examples:
  #{$0} pulls git/git

EOS
  exit
end

if ARGV.empty? then
  usage
elsif commands[ARGV[0]].nil?
  usage
elsif 1 < ARGV.length then
  repos=ARGV[1]
elsif ENV['GITHUB_REPOSITORY'].to_s != '' then
  repos=ENV['GITHUB_REPOSITORY']
else
  usage
end

command = ARGV[0]

if ENV['GITHUB_TOKEN'].to_s != '' then
  client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'] )
else
  client = Octokit::Client.new()
end
client.per_page = 100

$stdout.sync = true
puts "Target Repository : #{repos}"
puts "Get #{command}..."

commands[command][:get].call( client, repos )
last_response = client.last_response
num_of_items = last_response.data.length

File.open("#{command}.csv", 'w') do |f|
  f.print "\xEF\xBB\xBF" # BOM
  f.puts commands[command][:header]
  last_response.data.each{ |i|
    f.puts commands[command][:record].call(i)
  }

  until last_response.rels[:next].nil?
    next_page = last_response.rels[:next].href.match(/\Wpage=(\d+)/)[1]
    last_page = last_response.rels[:last].href.match(/\Wpage=(\d+)/)[1]
    print "[#{next_page} / #{last_page}]"
    sleep 0.1 # delay interval GitHub API Access
    last_response = last_response.rels[:next].get
    num_of_items += last_response.data.length
    last_response.data.each{ |i|
      f.puts commands[command][:record].call(i)
    }
    print "\r"
  end
end

puts "  Num of Items : #{num_of_items}"
puts "  Output File : #{command}.csv"
puts "  Rate Limit Remaining : #{client.ratelimit.remaining} / #{client.ratelimit.limit}"
puts "Done!"

