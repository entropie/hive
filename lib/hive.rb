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

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'


module Haml
  module Filters
    module RedCloth
      include Base

      def render(text)
        ::RedCloth.new(text).to_html
      end
    end
  end
end

    
def debug(str = "")
  puts "  #{str.empty? ? "  " : "->" } #{str}" #if $DEBUG
end
def error(str = "")
  puts "! #{str.empty? ? "  " : "->" } #{str}" #if $DEBUG
end



module Hive
  Version = [0, 0, 5]

  def Version.to_s
    "Hive %s" % Version.join(".")
  end

  Source = File.dirname(File.dirname(File.expand_path(__FILE__)))

  def Source.join(*fragments)
    File.join(Source, *fragments)
  end

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
    $: << lib_dir unless $:.include?(lib_dir)
  end

  require "queen"
  require "beehives"
  require "assets"
end

include Hive

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
