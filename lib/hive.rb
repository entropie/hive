#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require "rubygems"
require "bundler"

Bundler.require

require "logger"
require "find"
require "pp"
require "ostruct"

def debug(str = "")
  puts "#{str.empty? ? "  " : "->" } #{str}" if $DEBUG
end

module Hive
  Version = [0, 0, 3]

  def Version.to_s
    "Hive %s" % Version.join(".")
  end

  Source = File.dirname(File.dirname(File.expand_path(__FILE__)))

  def Source.join(*fragments)
    File.join(Source, *fragments)
  end

  $: << File.join(Source, "../innate/lib")
  $: << File.join(Source, "../ramaze/lib")

  # FIXME:
  $: << "/srv/innate/lib"
  $: << "/srv/ramaze/lib"

  require "innate"
  require "ramaze"

  def File.shorten(path, additional = "/beehives/")
    path.gsub(Source.join(additional), '')
  end

  QUEEN_LIBRARIES =
    [
     "lib/hive",
     "queen/lib"
    ]

  QUEEN_LIBRARIES.each do |base_lib|
    lib_dir = Source.join(base_lib)
    #puts "$: << #{lib_dir}"
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
