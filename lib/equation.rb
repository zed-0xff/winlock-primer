#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "primer")

class Equation
  attr_reader :answer, :letter

  # exclude letters that look like digits
  LETTERS = %w'X Y'
#    %w'A B C D E F G H   J K L M N P Q R S T U V W X Y' +
#    %w'a b c d e f g h i j k l m n p q r s t u v w x y'

  def initialize
    @letter = LETTERS.random
    @primer = Primer.new(
      rand(200), 
      1, 
      :actions        => %w'- * * / /',
      :add_mul_zero   => false,
      :max_rand_value => 100
    )
  end

  def to_s
    ps = @primer.to_s
    matches = []
    ps.scan(/\d+/){ matches << $~ }
    m = matches.random
    ps[m.begin(0)...m.end(0)] = @letter
    @answer = m.to_s.to_i
    "#{ps} = #{@primer.result}"
  end

  def self.generate
    new
  end
end

############################################################################

if __FILE__ == $0
  debug = ARGV.to_s.include?('-d')
  n = (ARGV.first || "10").to_i

  n.times do
    e = Equation.generate
    puts "#{e}; (#{e.letter} = #{e.answer})"
  end
end
