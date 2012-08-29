#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module Hive

  class Beehives < Hash

    BEEHIVE_DIR = "beehives"

    def initialize
    end

    def self.all
      @all ||= self.new
    end

    def self.size
      all.size
    end

    def self.[](obj)
      all[obj.to_sym]
    end

    def self.load(hive = nil)
      beehives = Dir.glob("#{Queen::ROOT}/#{BEEHIVE_DIR}/*")

      to_load = all

      beehives.inject(to_load) { |m, hv|
        symb = File.basename(hv).to_sym

        if to_load[symb]
          debug "skipping beehive '#{symb}'"
          next
        end

        debug ""
        debug "loading beehive: '#{symb}'"
        if not hive or (hive and File.basename(hv) == hive.to_s)
          m[symb] = Beehive.new(hv)
        end
      }

      to_load
    end
  end

  module BeehiveValidator
    BEEHIVE_DIRECTORIES = %w'beehive config lib public spec tmp'

    BEEHIVE_APP_FILES   = %w'controller helper layout public view start.rb'

    def validate
      validate_beehive_directories and
        validate_beehive_app_files
    end

    def validate_beehive_directories
      (Dir["#{path}/*"].map{ |dir| File.basename(dir) } &
       BEEHIVE_DIRECTORIES).size == BEEHIVE_DIRECTORIES.size
    end

    def validate_beehive_app_files
      (Dir["#{path}/beehive/*"].map{ |dir| File.basename(dir) } &
        BEEHIVE_APP_FILES).size == BEEHIVE_APP_FILES.size
    end
  end

  class Beehive

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def identifier
      @identifier ||= File.basename(path).to_sym
    end

    def mode
      :dev
    end

    def validate
      extend(BeehiveValidator).validate
    end

    def assets
      @assets ||= BeehiveAssets.new(self)
    end

    def queen
      Queen
    end

    def config
      @config ||= assets.config
    end

    def controller(&blk)
      Dir.glob("#{path}/beehive/controller/*.rb").each(&blk)
    end

    def stylesheet_for_app
      config.css.map{ |ss|
        "<link rel='stylesheet' rel='#{ss.first}' type='text/css' href='/css/#{ ss.last }' />"
      }.join("\n")
    end

    def javascripts_for_app
      config.js.map{ |ss| "<script type='text/javascript' src='/js/#{ ss }'></script>" }.join("\n")
    end

    def standalone!
      Queen.const_set("BEEHIVE", self)

      Ramaze.options.session.key = self.identifier

      debug "asking queen for global enviroment..."

      queen.controller do |queen_controller|
        debug "   queen controller: loading '#{queen_controller}'"
        require queen_controller
      end

      debug "calling beehive supervisors..."

      controller do |beehive_controller|
        debug " beehive controller: loading '#{beehive_controller}' [#{identifier}]"
        require beehive_controller
      end

      debug ""
      debug ""

      roots = [Queen::ROOT.join("queen")]
      roots.push(File.join(path, "beehive"))

      # views = [] #Queen::ROOT.join("queen", "view")
      # #views.push(File.join(path, "beehive", "view"))
      # Ramaze.options.views = ["view"]

      debug "starting #{identifier} in +++#{mode}+++"
      debug ""
      debug ""

      Ramaze.start(Queen.ramaze_opts.
                   merge(:port => config.port,
                         :root => roots))
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
