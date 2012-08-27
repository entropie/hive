#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module Hive

  class BeehiveAssets

    class Config
      attr_accessor :port
      attr_accessor :css
      attr_accessor :sass
      attr_accessor :js

      def method_missing(m, *args)
        self.send("#{m}=", *args)
      end
    end

    attr_reader :beehive, :config

    def initialize(beehive)
      @beehive = beehive
    end

    def config
      @config ||= Config.new
    end

    def beehive_specific
    end

    def read
      file = File.join(beehive.path, 'config', 'beehive.rb')
      instance_eval(File.readlines(file).join)
      self
    end

    def setup(&blk)
      config.instance_eval(&blk)
      config
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
