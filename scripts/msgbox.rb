#coding: utf-8

# non-blocking msgbox, invoked from check_time_limit.rb

require File.join(File.dirname(__FILE__), "..", "lib", "winapi")

def message_box msg
  msg = "#{msg}\0".encode("UTF-16LE")
  User32.message_box(nil, msg, msg, MB_SYSTEMMODAL|MB_ICONSTOP)
end

case ARGV.first
when '1'
  message_box "Ваше время истечет через 5 минут!"
when '2'
  message_box "Ваше время истекло!"
end
