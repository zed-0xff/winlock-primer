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

  POWERS_TBL = {}
  POWERS = 2..5
  MAX_POWER_RESULT = 999999

  def self.init
    return unless POWERS_TBL.empty?

    POWERS.each do |power|
      x = 1; result = 0
      while result < MAX_POWER_RESULT
        x += 1
        result = x**power
        POWERS_TBL[result] ||= []
        POWERS_TBL[result] << "#{x}**#{power}"
      end
    end
  end

  def initialize result, complexity, h = {}
    Primer.init if POWERS_TBL.empty?

    @result = result
    @debug = h[:debug]
    @s = h[:s] ? h[:s].dup : result.to_s
    puts "[.] #{self}" if @debug
    (2+rand(1)).times do
      complexize! %w'+ * / -'
      puts "[.] #{self}" if @debug
      raise self.inspect if eval(self.to_s) != self.result
    end
    #@s.tr!('()','')
    while @s.gsub('**','*').count('-+*/') < complexity
      complexize! %w'- * * / / **'
      puts "[.] #{self}" if @debug
      raise self.inspect if eval(self.to_s) != self.result
    end
    #while debracket!; end
#  rescue
#    p self
#    raise
  end

  ACTIONS = %w'+ - * /'

  def complexize! actions = ACTIONS
    n = @s.scan(/\d+/).size
    j = rand(n)
    i = 0
    # we need all numbers not having '**' at their right
    @s.scan(/\d+/) do |match|
      if i == j
        next if @s[$~.begin(0)-2,2] == '**'
        #next if @s[$~.end(0),2] == '**'
        range = $~.begin(0)...$~.end(0)       # range of number to replace with cpart
        cpart = num2expr(match.to_i, actions) 
        # cpart always has brackets, so first try to get rid of them
        ts = @s.dup
        ts[range] = cpart.tr('()','')
        if eval(ts) == @result
          # success! no excess brackets now
          @s = ts
        else
          # leave brackets in place
          @s[range] = cpart
        end
        break
      end
      i += 1
    end
    if @s =~ /^\([^()]+\)$/
      # strip global brackets
      @s = @s[1..-2]
    end
  end

  def to_s
    @s
  end

  private
  def num2expr result, actions0 = ACTIONS # convert number to expression
    actions = actions0.dup

    actions -= ['**'] if result == 0
    actions -= %w'+ * /' if result <= 1
    actions -= %w'*' if result.divisors.size <= 2
    #puts "[.] #{result}: #{actions.inspect}"

    if actions.include?('**')
      if POWERS_TBL[result]
        # boost the probability of known powers
        actions += ['**']*4
      elsif result != 1
        # lower the probability of x**1
        actions -= ['**'] if actions.uniq.size > 1 && rand > 0.1
      end
    end

    raise "no actions! (was: #{actions0.inspect})" if actions.empty?

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
      when '**'
        if rand < 0.01
          "#{result}**1" 
        elsif result == 1
          "#{rand(1000)}**0"
        elsif variants = POWERS_TBL[result]
          variants.random
        else
          "#{result}**1" 
        end
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

  def self.generate *args
    loop do
      begin
        primer = Primer.new(*args)
      rescue ZeroDivisionError
        redo
      end
      #redo if primer.to_s =~ /\([^\)]*\(/
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
    primer = Primer.generate(100+rand(1900), 6+rand(4), :debug => debug)
    puts primer
  end
end
