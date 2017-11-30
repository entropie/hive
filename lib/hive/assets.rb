#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#
require 'compass/sass_compiler'
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

      Compass.add_configuration(
        {
          :project_path     => Queen::BEEHIVE.app_root,
          :output_style     => :compressed,
          :sass_path        => "view/css",
          :css_path         => "public/css",
          :additional_import_paths => ["../vendor"]
        },'custom-name')


      files = beehive.config.css.map{ |_, f| f}

      afile = beehive.app_root("public/css/app.css")
      FileUtils.rm_f(afile, :verbose => true)

      str = ""
      File.open(afile, 'w+') do |fp|
        files.each do |file|
          compass_output_file = File.join("view/css", file.gsub(".css", ".sass"))
          if not file.include?("min") and not file.include?("pack")
            nfile = beehive.app_root("view/css/", file.gsub(".css", ".sass"))

            compiler = Compass.sass_compiler({
                                               :only_sass_files => [compass_output_file]
                                             })

            Dir.chdir(Queen::BEEHIVE.app_root) do
              compiler.compile!
            end
            ns = File.readlines(beehive.app_root("public/css", file)).join
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
