require '../lib/winapi'

def message_box msg
  msg = "#{msg}\0".encode("UTF-16LE")
  User32.message_box(nil, msg, msg, MB_SYSTEMMODAL|MB_ICONSTOP)
end

threads = 2.times.map do
  Thread.new do
    puts "[.] before msgbox"
    message_box 'foo'
    puts "[.] after msgbox"
  end
end

puts "[.] before join"
threads.each(&:join)
puts "[.] end of script"
