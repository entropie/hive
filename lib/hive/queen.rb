#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module Hive
  module Queen

    ROOT = Source

    class Config
      def engine
        :Haml
      end

      def layout
        "layout"
      end

    end

    def self.hives
      ::Beehives
    end

    def self.assets
    end

    def config
      @config ||= Config.new
    end

    def self.controller(&blk)
      Dir.glob("#{Source.join("queen/controller")}/*.rb").each(&blk)
    end

    def self.ramaze_opts
      { :adapter => :mongrel }
    end
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
