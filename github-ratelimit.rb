#!/usr/bin/env ruby
require 'octokit'

if ENV['GITHUB_TOKEN'].to_s != '' then
  client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'] )
else
  client = Octokit::Client.new()
end

puts client.ratelimit

