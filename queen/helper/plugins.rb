module Plugins
  def self.set_plugin_defaults_for(cls, opts)
    class << cls
      def config=(hsh)
        (@config ||= {}).merge!(hsh)
      end

      def config
        @config
      end
    end

    cls.config = opts
  end
end
