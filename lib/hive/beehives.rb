#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module Hive

  class Beehives < Hash

    BEHIVE_DIR = "beehives"

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
      beehives = Dir.glob("#{Queen::ROOT}/#{BEHIVE_DIR}/*")

      to_load = all

      beehives.inject(to_load) { |m, hv|
        symb = File.basename(hv).to_sym

        if to_load[symb]
          debug "skipping beehive '#{symb}'"
          next
        end

        debug "loading beehive: '#{symb}'"
        if not hive or (hive and File.basename(hv) == hive.to_s)
          m[symb] = Beehive.new(hv)
        end
      }

      to_load
    end
  end

  module BeehiveValidator
    BEEHIVE_DIRECTORIES = %w'beehive lib public spec tmp'

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

    def validate
      extend(BeehiveValidator).validate
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
