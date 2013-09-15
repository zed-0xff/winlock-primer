#!/usr/bin/env ruby

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
      complexity -= 1
    end
    @s.tr!('()','')
    complexity.times do
      complexize! %w'- * * / /'
      puts "[.] #{self}" if @debug
    end
    while debracket!; end
  end

  ACTIONS = %w'+ - * /'

  def complexize! actions = ACTIONS
    n = @s.scan(/\d+/).size
    j = rand(n)
    i = 0
    @s.scan(/\d+/) do |match|
      if i == j
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
    actions -= %w'+ * /' if result <= 1
    #puts "[.] #{result}: #{actions.inspect}"
    action = actions.random

    r = case action
      when '-'
        x = rand(1000)
        "#{result+x} - #{x}"
      when '+'
        x = rand(result-1) + 1
        "#{result-x} + #{x}"
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

    return "(#{r})"

    case action
      when '-', '+'
        # always add brackets
        r = "(#{r})"
      when '*', '/'
        # add brackets rarely
        r = "(#{r})" if rand(5) == 0
    end

    r
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
  debug = false
  n = (ARGV.first || "1").to_i

  n.times do
    primer = Primer.generate(100+rand(1900), 6+rand(4), debug)
    puts primer
  end
end
