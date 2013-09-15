#!/usr/bin/env ruby
require 'sinatra'
require 'haml'
require 'digest/md5'

require './primer'

##############################

get '/' do
  dt = Time.now
  seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
  srand(seed_string.to_i(10))
  @primers = []
  10.times do
    @primers << Primer.generate(100+rand(1900), 6+rand(4))
  end
  @password = Digest::MD5.hexdigest(seed_string)[0,8].upcase
  haml :index
end
