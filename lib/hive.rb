#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require "rubygems"
require "bundler"

Bundler.require

require "logger"
require "pp"
require "ostruct"

module Hive
  Version = [0, 0, 1]

  Source = File.dirname(File.dirname(File.expand_path(__FILE__)))

  def Source.join(*fragments)
    File.join(Source, *fragments)
  end

  $: << File.join(Source, "../innate/lib")
  $: << File.join(Source, "../ramaze/lib")
  require "innate"
  require "ramaze"


  def debug(str = "")
    puts "#{str.empty? ? "  " : "->" } #{str}"
  end

  QUEEN_LIBRARIES =
    [
     "lib/hive",
     "queen/lib",
     "queen/helpers"
    ]

  QUEEN_LIBRARIES.each do |base_lib|
    lib_dir = Source.join(base_lib)
    puts "$: << #{lib_dir}"
    $: << lib_dir unless $:.include?(lib_dir)
  end

  require "queen"
  require "beehives"
  require "assets"

end

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
