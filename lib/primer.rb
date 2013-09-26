#!/usr/bin/env ruby
#coding: utf-8

class Fixnum
  def divisors
    r = [1]
    2.upto(Math.sqrt(self)) do |x|
      r << x if self%x == 0
    end
    r << self
    r
  end
end

class Array
  def random
    self[rand(self.size)]
  end
end

class Primer
  attr_accessor :result

  def initialize result, complexity, debug = false
    @result = result
    @debug = debug
    @s = result.to_s
    puts "[.] #{self}" if @debug
    (2+rand(1)).times do
      complexize! %w'+'
    end
    @s.tr!('()','')
    while @s.count('-+*/') < complexity
      complexize! %w'- * * / / **'
      puts "[.] #{self}" if @debug
    end
    while debracket!; end
  end

  ACTIONS = %w'+ - * /'

  def complexize! actions = ACTIONS
    n = @s.scan(/\d+/).size
    j = rand(n)
    i = 0
    # we need all numbers not surrounded by '**'s
    @s.scan(/\d+/) do |match|
      if i == j
        next if @s[$~.begin(0)-2,2] == '**'
        next if @s[$~.end(0),2] == '**'
        @s[$~.begin(0)...$~.end(0)] = num2expr(match.to_i, actions)
        break
      end
      i += 1
    end
    if @s.count('(') == 1 && @s.count(')') == 1 && @s =~ /^\(.+\)$/
      # strip global brackets
      @s = @s[1..-2]
    end
  end

  def to_s
    @s
  end

  private
  def num2expr result, actions = ACTIONS # convert number to expression
    actions = actions.dup

    if actions.include?('**')
      t = Math.sqrt(result).to_i
      if t*t == result
        if result > 4
          return "#{t}**2"
        else
          return "#{t}**2" if rand < 0.2
        end
      end
      return "#{result}**1" if rand < 0.01
      return "#{rand(1000)}**0" if rand < 0.1 && result == 1
      actions -= ['**']
    end

    actions -= %w'+ * /' if result <= 1
    actions -= %w'*' if result.divisors.size <= 2
    #puts "[.] #{result}: #{actions.inspect}"
    action = actions.random

    r = case action
      when '-'
        if rand < 0.1 && (actions.include?('*') || actions.include?('/'))
          "#{result} - #{rand(1000)} * #{rand(1000)} / #{rand(1000)} * 0"
        else
          x = rand(1000)
          "#{result+x} - #{x}"
        end
      when '+'
        if rand < 0.1 && (actions.include?('*') || actions.include?('/'))
          "#{result} + #{rand(1000)} * #{rand(1000)} / #{rand(1000)} * 0"
        else
          x = rand(result-1)
          "#{result-x} + #{x}"
        end
      when '*'
        divisors = result.divisors
        x = divisors.random
        if (x == 1 || x == result) && divisors.size > 2 && rand(10) != 0
          x = (divisors - [1,result]).random
        end
        "#{result/x} * #{x}"
      when '/'
        x = rand(15) + 2
        "#{result*x} / #{x}"
      end

    "(#{r})" # always add brackets
  end

  def debracket!
    @s.scan(/\([^()]*\([^()]*\)[^()]*\)/) do |match|
      if eval(match) == eval(match.tr('()',''))
        @s.sub!(match, '(' + match.tr('()','') + ')')
        puts "[d] #@s" if @debug
        return true
      end
    end
    false
  end

  # generate primer with max bracket depth = 1
  def self.generate answer, complexity, debug = false
    loop do
      primer = Primer.new(answer, complexity, debug)
      redo if primer.to_s =~ /\([^\)]*\(/
      raise "#{primer.inspect}:\n  #{primer.result} != #{eval(primer.to_s)}" if primer.result != eval(primer.to_s)
      return primer
    end
  end
end

############################################################################

if __FILE__ == $0
  debug = ARGV.to_s.include?('-d')
  n = (ARGV.first || "10").to_i

  n.times do
    primer = Primer.generate(100+rand(1900), 6+rand(4), debug)
    puts primer
  end
end
