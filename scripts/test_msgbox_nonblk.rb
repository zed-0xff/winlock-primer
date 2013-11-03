require 'rubygems'

def rubyw
  ruby = Gem.ruby
  rubyw = ruby.sub /ruby\.exe/, "rubyw.exe"
  File.executable?(rubyw) ? rubyw : ruby
end

puts "[.] before msgbox 1"
system "start", rubyw, File.expand_path("msgbox.rb", File.dirname(__FILE__)), '1'
puts "[.] after msgbox 1"
system "start", rubyw, File.expand_path("msgbox.rb", File.dirname(__FILE__)), '2'
puts "[.] after msgbox 2"
