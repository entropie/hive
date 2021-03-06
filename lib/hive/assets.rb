#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#



module Hive

  class BeehiveAssets

    def self.make_static_js
      beehive = Queen::BEEHIVE

      files = beehive.config.js.map{ |f| beehive.app_root("public/js", f)}

      files.reject!{ |f| if File.exist?(f) then false else puts "skipping #{f}"; true end }

      afile = beehive.app_root("public/js/app.js")
      File.open(afile, 'w+') do |fp|
        files.each do |file|
          if not file.include?("min") and not file.include?("pack")
            puts "uglify: #{file}"
            fp.puts Uglifier.new.compile(File.read(file))
          else
            puts "uglify skipped: #{file}"
            fp.puts File.readlines(file).join
          end
          fp.puts ""
        end
      end
      puts ">>> #{afile} is #{File.size(afile)/1024} KBytes"
    end

    def self.make_static_css
      beehive = Queen::BEEHIVE

      Compass.configuration do |a|
        a.project_path =     Queen::BEEHIVE.app_root
        a.output_style =    :compressed
        a.sass_path     =   "view/css"
        a.css_path      =   "public/css"
        a.additional_import_paths = ["../vendor"]
      end

      files = beehive.config.css.map{ |_, f| f}

      afile = beehive.app_root("public/css/app.css")

      str = ""
      File.open(afile, 'w+') do |fp|

        files.each do |file|
          fp.puts "/*** queen taling, be quiet: #{file} ***/"
          compass_output_file = beehive.app_root("public/css", "generated_#{file}")
          if not file.include?("min") and not file.include?("pack")
            nfile = beehive.app_root("view/css/", file.gsub(".css", ".sass"))
            compiler = Compass.compiler.compile(nfile, compass_output_file)

            ns = File.readlines(compass_output_file).join
            fp.puts(ns)
            puts "sass2css: #{nfile}"
          else
            nfile = beehive.app_root("public/css/", file)
            puts "sass2css: ignoring: #{file}"
            fp.puts File.readlines(nfile).join
          end
          fp.puts ""
        end

      end
      puts ">>> #{afile} is #{File.size(afile)/1024} KBytes"
    end

    class Config
      attr_accessor :port
      attr_accessor :css
      attr_accessor :sass
      attr_accessor :js
      attr_accessor :host
      attr_accessor :database
      attr_accessor :facebook
      attr_accessor :roles
      attr_accessor :domain
      attr_accessor :twitter
      attr_accessor :recaptcha
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
