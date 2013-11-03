#!/usr/bin/env ruby

require 'yaml'
require 'digest/md5'

ROOT = File.expand_path(File.dirname(__FILE__), "..")

dt = Time.now + ARGV.first.to_i*24*3600
seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
pw = Digest::MD5.hexdigest(seed_string)[0,8].upcase

puts pw
