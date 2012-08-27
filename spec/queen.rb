#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require File.join(File.dirname(File.expand_path($0)), "spec_helper")

describe "The Queen" do

  it "should have a baseroot" do
    Queen::ROOT.size.should > 1
  end

  it "should respond to hives" do
    Queen.should.respond_to?(:hives)
  end

  it "should be able to load testhive" do
    hives = Queen::hives.load(:test)
    hives.size.should == 1
  end

  it "should have loaded the testhive" do
    Queen::hives.size.should == 1
  end

  it "should be possible to load a hive via symbol" do
    Queen::hives[:test].should.not == nil
  end
end

describe "BeehiveValidator" do
  @beehive = Queen::hives[:test]

  it "should be possible to validate a beehive" do
    @beehive.validate.should == true
  end
end


=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
