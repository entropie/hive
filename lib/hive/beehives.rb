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
      :dev                      # FIXME: hardcoded
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
      config.js.map{ |js| "<script type='text/javascript' src='/js/#{ js }'></script>" }.join("\n")
    end

    def view_path
      File.join(path, "beehive", "view")
    end


    def ramaze_opts
      roots = [ Queen::ROOT.join("queen"), File.join(path, "beehive") ]

      opts = Queen.ramaze_opts.merge(:port => config.port,
                                     :root => roots,
                                     :host => "0.0.0.0") # FIXME:

      layout_dir = File.join(path, "beehive", "layout")

      if File.exist?(layout_dir)
       opts[:layouts] = layout_dir
      end

      opts
    end

    def require_enviroment!
      paths = [ Source.join("helpers"),
                File.join(path, "helpers"),
                File.join(path, "lib", identifier.to_s)
              ]

      paths.each do |source_dir|
        debug " claiming honey from '#{File.shorten(source_dir, '')}'"
        Dir.glob("#{source_dir}/**/*.rb").each do |file|
          debug "   #{File.shorten(file)}"
          require file
        end
      end
    end

    def standalone!
      Queen.const_set("BEEHIVE", self)

      # I had wierd problems during developing a very similiar app with
      # memchached and multiple apps running. Sometimes the session was
      # shared beetween different apps. This should fix it.
      Ramaze.options.session.key = self.identifier.to_s

      debug "asking queen for global enviroment..."

      queen.controller do |queen_controller|
        debug " queen controller: loading '#{File.shorten(queen_controller, '')}'"
        require queen_controller
      end

      debug "calling beehive supervisors..."

      controller do |beehive_controller|
        debug " beehive controller: loading '#{File.shorten(beehive_controller)}' [#{identifier}]"
        require beehive_controller
      end

      require_enviroment!

      Ramaze::Cache.options do |cache|
        cache.names = [:session, :user]
        cache.default = Ramaze::Cache::MemCache
      end

      debug; debug;
      debug "starting #{identifier} in +++#{mode}+++"
      debug; debug


      opts = ramaze_opts
      debug "ramaze opts\n #{PP.pp(opts, '')}"
      Ramaze.start(opts)
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
