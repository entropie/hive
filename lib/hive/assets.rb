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
      attr_accessor :host

      attr_reader   :beehive

      def initialize(beehive)
        @beehive = beehive
      end

    end

    attr_reader :beehive, :config

    def initialize(beehive)
      @beehive = beehive
    end

    def config
      @config ||= Config.new(beehive)
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
