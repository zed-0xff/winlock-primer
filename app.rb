#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'digest/md5'
require 'yaml'
require File.join(File.dirname(__FILE__), "lib", "primer")
require File.join(File.dirname(__FILE__), "lib", "winapi")

TIME_LIMIT_DATA_FILE = File.join(ENV['USERPROFILE'], "ctl.sys")

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

get '/status' do
  config = read_config
  if config['userprofile']
    fname = File.join(config['userprofile'], TIME_LIMIT_DATA_FILE)
    if File.exist?(fname)
      data = nil
      begin
        data = Marshal.load(File.binread(fname))
      rescue
      end
      if data.is_a?(Array)
        r = data.inspect
        if data[1].is_a?(Fixnum)
          r << "\n(%1.1f hours)" % (data[1]/3600.0)
        end
        r
      else
        "[?] no data"
      end
    else
      "TIME_LIMIT_DATA_FILE not exists"
    end
  else
    "userprofile config variable is not set"
  end
end
