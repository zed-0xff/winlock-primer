require 'spec_helper'
require File.expand_path("../lib/primer", File.dirname(__FILE__))

describe Primer do
  it "should generate 10000 primers" do
    a = 10000.times.map{ Primer.generate(100+rand(1900), 6+rand(4)) }.map(&:to_s)
    a.uniq.size.should > 9000
  end

  it "should not hang on (252**2 / 4**2) / 3**2" do
    s = '(252**2 / 4**2) / 3**2'
    primer = Primer.generate(441, 9, :s => s)
    primer.to_s.should_not == s
    eval(primer.to_s).should == eval(s)
  end
end
