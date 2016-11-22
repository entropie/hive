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

    def self.each(&blk)
      all.each(&blk)
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

        # debug ""
        # debug "loading beehive: '#{symb}'"
        if not hive or (hive and File.basename(hv) == hive.to_s)
          m[symb] = Beehive.new(hv)
        end
        m
      }

      to_load
    end
  end

  module BeehiveValidator
    BEEHIVE_DIRECTORIES = %w'beehive config lib public spec tmp plugin log'

    BEEHIVE_APP_FILES   = %w'controller helper layout public view model migration start.rb'

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

  module BeehiveCreator
    include BeehiveValidator
    include FileUtils

    REPLACER = {
      /%%%name%%%/   => proc{ identifier },
      /%%%domain%%%/ => proc { config.domain || @domain || identifier }
    }

    def root
      @root ||= Queen::ROOT
    end

    def create!(domain)
      @domain = domain
      create_beehive_directories!
      create_beehive_app_files!

      create_config_ru!
      copy_default_config_files!

      copy_defaults_from(:ramaze)

      validate
    end

    def substitute_variables(file)
      puts "attemping to replace placeholder in #{File.basename(file)}..."

      content = File.readlines(file).join

      REPLACER.each do |r,b|
        content.gsub!(r, instance_eval(&b).to_s)
      end
      File.open(file, 'w+'){ |fp| fp.puts(content) }
    end

    def copy_default_config_files!
      cfgs = %w'nginx.conf unicorn.rb unicorn_init.sh beehive.rb'

      cfgs.each do |c|
        file = File.join(root, "config", "#{c}.default")
        outfile = File.join(path, 'config', c)
        cp(file, outfile, :verbose => true)

        substitute_variables(outfile)
      end
    end

    def copy_defaults_from(what)
      file = File.join(root, "defaults", what.to_s, "beehive")
      cp_r(file, File.join(path), :verbose => true)
    end

    def create_config_ru!
      file = File.join(root, "config", "config.ru.default")
      cp(file, File.join(path, 'config.ru'), :verbose => true)
    end

    # def create_start_rb!
    #   file = File.join(root, "config", "start.rb.default")
    #   cp(file, File.join(path, 'beehive', 'start.rb'), :verbose => true)
    # end

    # def create_default_config!
    #   file = File.join(root, "config", "beehive.rb.default")
    #   cp(file, File.join(path, 'config', 'beehive.rb'), :verbose => true)
    # end

    def create_beehive_directories!
      BEEHIVE_DIRECTORIES.each do |dir|
        mkdir_p(File.join(path, dir), :verbose => true)
        FileUtils.touch(File.join(path, dir, ".keep"), :verbose => true)
      end
    end

    def create_beehive_app_files!
      BEEHIVE_APP_FILES.reject{ |af| af.include?(".")}.each do |dir|
        mkdir_p(File.join(path, "beehive", dir), :verbose => true)
        FileUtils.touch(File.join(path, "beehive", dir, ".keep"), :verbose => true)
      end
    end
  end

  module BeehiveCMDInterface
    def list(&blk)
      res = []
      Find.find(path) do |file|
        if File.basename(file) == ".git"
          res << file
          Find.prune
        end
        res << file
      end

      res = res.sort.map{ |f| File.shorten(f)}
    end
  end

  class Beehive

    include Term::ANSIColor

    attr_reader :path

    def self.create(path)
      beehive = new("#{Queen::ROOT}/#{Beehives::BEEHIVE_DIR}/#{path}").extend(BeehiveCreator)
    end

    def inspect
      "%s -> %s" % [red{ identifier.to_s }, path]
    end

    def initialize(path)
      @path = path
    end

    def identifier
      @identifier ||= File.basename(path).to_sym
    end

    def mode
      @mode || :dev
    end

    def production?
      mode == :production || mode == :live
    end

    def development?
      mode == :dev
    end

    def validate
      extend(BeehiveValidator).validate
    end

    def list
      extend(BeehiveCMDInterface).list
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

    def static_url_apendix
      REV
    end

    def controller(&blk)
      Dir.glob("#{path}/beehive/controller/*.rb").sort_by{ |f|
        File.basename(f) == "#{identifier}.rb" ? 1 : 0
      }.reverse.each(&blk)
    end

    def stylesheets_for_app
      if mode == :live
        BeehiveAssets.make_static_css unless File.exist?(app_root("public/css/app.css"))
        "<link rel='stylesheet' type='text/css' href='/css/app.css?#{static_url_apendix}' />"
      else
        config.css.map{ |ss|
          csspath = if ss.last[0..0] == "/" then ss.last else "/css/#{ ss.last }" end
          "<link rel='stylesheet' type='text/css' href='#{ csspath }?#{static_url_apendix}' />"
        }.join("\n")
      end
    end

    def javascripts_for_app
      if mode == :live
        unless File.exist?(app_root("public/js/app.js"))
          BeehiveAssets.make_static_js
        end
        "<script type='text/javascript' src='/js/app.js?#{static_url_apendix}'></script>"
      else
        
        config.js.map{ |js|
          prfx = js =~ /^\// ? "" : "/js/"
          "<script type='text/javascript' src='#{prfx}/#{ js }?#{static_url_apendix}'></script>" }.join("\n")
      end
    end

    def view_path(*args)
      @view_path ||= File.join(path, "beehive", "view", *args)
    end

    def app_root(*args)
      File.join(path, 'beehive', *args)
    end

    def media_path(*args)
      File.join(path, "media", *args)
    end


    def ramaze_opts
      roots = [ Queen::ROOT.join("queen"), File.join(path, "beehive") ].reverse

      opts = Queen.ramaze_opts.merge(:port => config.port,
                                     :root => roots,
                                     :host => config.host)

      layout_dir = File.join(path, "beehive", "layout")
      # if File.exist?(layout_dir)
      #  opts[:layouts] = layout_dir
      # end

      opts
    end

    def require_enviroment!
      paths = [ Source.join("queen", "helper"),
                File.join(path, "helper"),
                File.join(path, "lib", identifier.to_s)
              ]

      paths.each do |source_dir|
        debug " claiming honey from '#{File.shorten(source_dir, '')}'"
        Dir.glob("#{source_dir}/**/*.rb").each do |file|
          debug "   #{File.shorten(file, "")}"
          require file
        end
      end
    end

    def require_plugins!
    end

    def require_models!
      debug "loading models"
      Dir.glob("#{app_root("model")}/*.rb").each do |model|
        debug " #{File.shorten(model)}"
        require model
      end
    end

    def set_enviroment(options = { })
      Queen.const_set("BEEHIVE", self)

      Queen.const_set("REV", File.readlines(self.app_root("../.git/refs/heads/master")).join[0..6])
      
      # I had wierd problems during developing a very similiar app with
      # memchached and multiple apps running. Sometimes the session was
      # shared beetween different apps. This should fix it.
      Ramaze.options.session.key = self.identifier.to_s
      Ramaze::Cache.options.session = Ramaze::Cache::MemCache

      require_enviroment!
      require_plugins!

      require_models! if config.database

      debug "asking queen for global enviroment..."
      queen.controller do |queen_controller|
        debug " queen controller: loading '#{File.shorten(queen_controller, '')}'"
        require queen_controller
      end

      debug "gathering plugins upgrade to make the bees rock"
      queen.plugins do |plugin_controller|
        debug " queen plugin controller: loading '#{File.shorten(plugin_controller, '')}'"
        require plugin_controller
      end

      debug "calling beehive supervisors..."
      controller do |beehive_controller|
        debug " beehive controller: loading '#{File.shorten(beehive_controller)}' [#{identifier}]"
        require beehive_controller
      end

    end

    def start!(opts)
      set_enviroment(opts)
      @mode = opts[:mode]

      delete_generated_files
      debug; debug;
      debug white { "starting #{identifier} in +++#{mode}+++"}
      debug; debug

      ropts = ramaze_opts.merge(opts)
      Ramaze.start(ropts)
    end

    def delete_generated_files
      [app_root("public/css/app.css"), app_root("public/js/app.js")].each do |gf|
        FileUtils.rm(gf, :verbose => true) if File.exists?(gf)
      end
    end

    def standalone!
      set_enviroment
      delete_generated_files

      Ramaze.middleware :dev do
        use Rack::Lint
        use Rack::CommonLogger, Ramaze::Log
        use Rack::ShowExceptions
        use Rack::Head
        use Rack::Deflater
        use Rack::ShowStatus
        run Ramaze.core
      end

      @mode = :test
      debug; debug;
      debug white { "starting #{identifier} in +++#{mode}+++"}
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
