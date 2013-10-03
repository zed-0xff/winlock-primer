#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'digest/md5'
require 'yaml'

require File.join(File.dirname(__FILE__), "lib", "primer")

##############################

def read_config
  fname = File.join(File.dirname(__FILE__), "config", "primer.yml")
  config = {}
  config = YAML::load_file(fname) if File.exist?(fname)
  if (Time.now.saturday? || Time.now.sunday?) && config['primers_weekend']
    config['primers'] = config['primers_weekend']
  end
  config['primers'] ||= 10

  config['modules'] = YAML::load_file(File.join(File.dirname(__FILE__), "data", "index.yml"))
  config['modules'].each do |k,cfg|
    raise unless k =~ /\A[a-z0-9_]+\Z/i
    cfg['data'] = YAML::load_file( File.join(File.dirname(__FILE__), "data", k+".yml") )
  end

  config
end

##############################

get '/' do
  config = read_config

  dt = Time.now
  seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
  srand(seed_string.to_i(10))
  @primers = []
  config['primers'].times do
    @primers << Primer.generate(100+rand(1900), 6+rand(4))
  end
  @password = Digest::MD5.hexdigest(seed_string)[0,8].upcase
  @modules = config['modules']
  haml :index
end
