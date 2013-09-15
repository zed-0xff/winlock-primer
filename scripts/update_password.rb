#coding: utf-8
# this file must be scheduled run daily at 00:01
# with enabled option "run immediately if skipped"

require 'yaml'
require 'digest/md5'

def read_config
  fname = File.join(File.dirname(__FILE__), "..", "config", "primer.yml")
  config = {}
  config = YAML::load_file(fname) if File.exist?(fname)
  config
end

user = read_config['user']
return if !user || user =~ /[\x00-\x20]/ || user[/[\\\/:\|\[\]\{\} ]/]

dt = Time.now
seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
new_password = Digest::MD5.hexdigest(seed_string)[0,8].upcase

system "net user #{user} #{new_password}"
