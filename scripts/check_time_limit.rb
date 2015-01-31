#coding: utf-8

# this file must be run from the registry of target user

require 'rubygems'
require "ffi"
require 'yaml'
require 'digest/md5'
require File.join(File.dirname(__FILE__), "..", "lib", "winapi")

###############################################################################

# all limits are in seconds
t = Time.now.month*100 + Time.now.day
if t >= 528 && t <= 902
  # summer
  DAILY_LIMIT_WORKDAYS = 3600*4
  DAILY_LIMIT_WEEKENDS = 3600*4
else
  # all other year
  DAILY_LIMIT_WORKDAYS = 3600*2
  DAILY_LIMIT_WEEKENDS = 3600*3
end

###############################################################################

CHECK_PERIOD   = 120 # (seconds)
DATA_FILE      = File.join(ENV['USERPROFILE'], "ctl.sys")

###############################################################################

def message_box msg
  msg = "#{msg}\0".encode("UTF-16LE")
  User32.message_box(nil, msg, msg, MB_SYSTEMMODAL|MB_ICONSTOP)
end

def rubyw
  ruby = Gem.ruby
  rubyw = ruby.sub /ruby\.exe/, "rubyw.exe"
  File.executable?(rubyw) ? rubyw : ruby
end

def message_box_nonblk x
  system "start", rubyw, File.expand_path("msgbox.rb", File.dirname(__FILE__)), x.to_s
end

def limit
  t1 = Time.now
  (t1.sunday? || t1.saturday?) ? DAILY_LIMIT_WEEKENDS : DAILY_LIMIT_WORKDAYS
end

def lock_user!
  return if @data[1] < limit # prevent race condition

  dt = Time.now
  seed_string = "%02d%02d%04d" % [dt.day, dt.month, dt.year]
  old_password = Digest::MD5.hexdigest(seed_string)[0,8].upcase

  seed_string += "-LOCKED"
  new_password = Digest::MD5.hexdigest(seed_string)[0,8].upcase

  #system "net user #@user #{new_password}"
  Netapi32.net_user_change_password nil, nil,
    "#{old_password}\0".encode("UTF-16LE"),
    "#{new_password}\0".encode("UTF-16LE")

  #message_box "Ваше время истекло!"
  message_box_nonblk 2
  sleep 4
  User32.lock_workstation
end

# show messagebox 5 minutes before lock
def show_5min_notification
  #message_box "Ваше время истечет через 5 минут!"
  message_box_nonblk 1
  system Gem.ruby, File.expand_path("msgbox.rb", File.dirname(__FILE__)), '1'
end

def save_data
  File.binwrite(DATA_FILE, Marshal.dump(@data))
end

def log_activity
  t0 = @data[0]
  t1 = Time.now
  if t0.year != t1.year || t0.month != t1.month || t0.mday != t1.mday
    # waked next day after system sleep
    @data = [Time.now, 0]
  else
    @data[1] += CHECK_PERIOD
    save_data

    if @data[1] >= limit
      lock_user!
    elsif limit-@data[1] <= 5*60
      show_5min_notification
    end
  end
end

def main_loop
  loop do
    buf = [8, 0].pack('l*')
    User32.get_last_input_info(buf)
    last_input_tick = buf.unpack('l*')[1]

    cur_tick = Kernel32.get_tick_count

    if (cur_tick - last_input_tick)/1000 <= CHECK_PERIOD
      # there was activity
      log_activity
    end
    sleep CHECK_PERIOD
  end
end

def read_config
  fname = File.join(File.dirname(__FILE__), "..", "config", "primer.yml")
  config = {}
  config = YAML::load_file(fname) if File.exist?(fname)
  config
end

@user = read_config['user']
return if !@user || @user =~ /[\x00-\x20]/ || @user[/[\\\/:\|\[\]\{\} ]/]
@user = @user.encode('cp1251')
return if !@user || @user =~ /[\x00-\x20]/ || @user[/[\\\/:\|\[\]\{\} ]/]

@data = nil
begin
  @data = Marshal.load(File.binread(DATA_FILE)) if File.exist?(DATA_FILE)
rescue
end

@data ||= [Time.now, 0]

main_loop

