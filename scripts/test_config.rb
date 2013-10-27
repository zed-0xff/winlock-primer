#!/usr/bin/env ruby
require 'yaml'
require 'pp'

fname = File.join(File.dirname(__FILE__), "..", "config", "primer.yml")

config = YAML::load_file fname
pp config

if userprofile = config['userprofile']
  puts "[.] userprofile exists? = #{File.exist?(userprofile)}"
  puts "[.] converting to CP1251 .."
  userprofile.encode!("cp1251")
  puts "[.] userprofile exists? = #{File.exist?(userprofile)}"
  puts "[.] converting to CP866 .."
  userprofile.encode!("cp866")
  puts "[.] userprofile exists? = #{File.exist?(userprofile)}"
end
