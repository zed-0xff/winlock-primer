#coding: utf-8

# this file must be run from the registry of target user

require "ffi"
require 'yaml'
require 'digest/md5'

###############################################################################

# in seconds
DAILY_LIMIT_WORKDAYS = 3600*2
DAILY_LIMIT_WEEKENDS = 3600*4

###############################################################################

CHECK_PERIOD   = 120 # (seconds)
DATA_FILE      = File.join(ENV['USERPROFILE'], "ctl.sys")

MB_SYSTEMMODAL = 0x1000
MB_ICONSTOP    = 0x10

###############################################################################

module User32
  extend FFI::Library

  ffi_lib "user32"
  ffi_convention :stdcall

  # use MessageBoxA if you want to pass it strings with ASCII encoding
  attach_function :message_box, 'MessageBoxW', 
                  [ :pointer, :buffer_in, :buffer_in, :int ], :int

  attach_function :get_last_input_info, 'GetLastInputInfo', [:pointer], :int
  attach_function :lock_workstation, 'LockWorkStation', [], :int
end

module Kernel32
  extend FFI::Library

  ffi_lib "kernel32"
  ffi_convention :stdcall

  attach_function :get_tick_count, 'GetTickCount', [], :int
end

def message_box msg
  msg = "#{msg}\0".encode("UTF-16LE")
  User32.message_box(nil, msg, msg, MB_SYSTEMMODAL|MB_ICONSTOP)
end

def lock_user!
  dt = Time.now
  seed_string = "%02d%02d%04d-LOCKED" % [dt.day, dt.month, dt.year]
  new_password = Digest::MD5.hexdigest(seed_string)[0,8].upcase

  system "net user #@user #{new_password}"
  message_box "Ваше время истекло!"
  sleep 5
  User32.lock_workstation
end

# show messagebox 5 minutes before lock
def show_5min_notification
  message_box "Ваше время истечет через 5 минут!"
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

    limit = (t1.sunday? || t1.saturday?) ? DAILY_LIMIT_WEEKENDS : DAILY_LIMIT_WORKDAYS
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

