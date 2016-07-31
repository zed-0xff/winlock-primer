#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'digest/md5'
require 'yaml'
require 'json'
require 'date'
require 'erb'
require File.join(File.dirname(__FILE__), "lib", "primer")
require File.join(File.dirname(__FILE__), "lib", "equation")

def windows?
  RUBY_PLATFORM['mingw']
end

require File.join(File.dirname(__FILE__), "lib", "limits")
require File.join(File.dirname(__FILE__), "lib", "winapi") if windows?

TIME_LIMIT_DATA_FILE = "ctl.sys"

##############################
helpers do
  def scramble a
    a.map do |answer|
      case answer
      when String
        answer.each_char.map(&:ord).join(',')
      when Array
        scramble answer
      else
        answer
      end
    end
  end
end
##############################

def read_config
  fname = File.join(File.dirname(__FILE__), "config", "primer.yml")
  config = {}
  config = YAML::load_file(fname) if File.exist?(fname)
  if (Time.now.saturday? || Time.now.sunday?) && config['primers_weekend']
    config['primers'] = config['primers_weekend']
  end
  config['primers'] ||= 10

  config['equations'] ||= 3

  config['modules'] = YAML::load_file(File.join(File.dirname(__FILE__), "data", "index.yml"))
  config['modules'].each do |k,cfg|
    raise unless k =~ /\A[a-z0-9_]+\Z/i
    data = File.read File.join(File.dirname(__FILE__), "data", k+".yml"), :encoding => 'UTF-8'
    if data['<%='] && data['%>']
      data = ERB.new(data).result
    end
    cfg['data'] = YAML.load data
  end

  user = config['user']
  raise "invalid username" if !user || user =~ /[\x00-\x20]/ || user[/[\\\/:\|\[\]\{\} ]/]
  user = user.encode('cp1251')
  raise "invalid username" if !user || user =~ /[\x00-\x20]/ || user[/[\\\/:\|\[\]\{\} ]/]
  config['user'] = user

  config
end

def today_limit_over?
  data = read_data_file
  data && data[0].to_date == Time.now.to_date && data[1] >= limit
end

def update_password user, seed_string
  return unless windows?
  seed_string += "-LOCKED" if today_limit_over?
  new_password = Digest::MD5.hexdigest(seed_string)[0,8].upcase
  system "net user #{user} #{new_password}"
end

def pass_for_date dt
  seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
  Digest::MD5.hexdigest(seed_string)[0,8].upcase
end

def read_data_file
  config = read_config
  data = nil
  if config['userprofile']
    fname = File.join(config['userprofile'], TIME_LIMIT_DATA_FILE)
    if File.exist?(fname)
      data = nil
      begin
        data = Marshal.load(File.binread(fname))
      rescue
      end
    end
  end
  data
end

def write_data_file data
  config = read_config
  if config['userprofile']
    fname = File.join(config['userprofile'], TIME_LIMIT_DATA_FILE)
    File.binwrite(fname, Marshal.dump(data))
  end
end

def shutdown!
  system "shutdown /s /t 10"
  $?
end

##############################

get '/' do
  config = read_config

  dt = Time.now
  seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
  update_password config['user'], seed_string
  srand(seed_string.to_i(10))

  @primers = []
  config['primers'].times do
    @primers << Primer.generate(100+rand(1900), 7+rand(4))
  end

  @equations = []
  config['equations'].times do
    @equations << Equation.generate
  end

  @password = Digest::MD5.hexdigest(seed_string)[0,8].upcase
  @modules = config['modules']
  @answers = []
  @subtitle = today_limit_over? ? '[OVER]' : ''
  haml :index
end

get '/status' do
  data = read_data_file
  if data.is_a?(Array)
    if data[1].is_a?(Fixnum)
      data << "%1.1f hours" % (data[1]/3600.0)
    end
    if today_limit_over?
      data << "OVER"
    end
    data.to_json
  else
    "[?] no data"
  end
end

get '/admin' do
  haml :admin
end

post '/admin' do
  config = read_config
  if Digest::MD5.hexdigest(params[:pw].to_s) == config['admin_pass']
    @h = {}
    3.downto(-5).each do |delta|
      dt = Date.today + delta
      ps = pass_for_date dt
      @h[ dt ] = ps
    end

    if params[:value]
      data = read_data_file
      data[1] = params[:value].to_i
      write_data_file data
    end

    data = read_data_file
    @value = data[1]
    haml :admin2
  else
    haml :admin
  end
end

post '/lock' do
  User32.lock_workstation
end

post '/shutdown' do
  shutdown!
end

post '/shut_if_over' do
  if today_limit_over?
    shutdown!
  else
    "NOT_YET"
  end
end

