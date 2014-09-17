#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

p Dir.pwd

load "lib/hive.rb"

include Hive

namespace :beehives do

  Hives = Queen::hives.load
  include Queen
#  include Term::ANSIColor

  $DEBUG = true if ENV["DEBUG"] == "true"

  desc "give live to a new hive"
  task :create do
    identifier = ENV['IDENTIFIER']
    raise "no identifier given; use IDENTIFIER=foo rake beehives:create" unless identifier

    beehive = Hive::Beehive.create(identifier)
    if beehive.create!
      puts green { "done and valid!" }
      puts red { "make sure to edit #{File.join(beehive.path, 'config', 'beehive.rb')}" }
    end
  end

  desc "list of all beehives aka. apps"
  task :ls do
    Hives.each do |ident, hive|
      p hive
    end
  end

  Hives.each do |ident, hive|
    namespace ident do

      desc "starts beehive in standalone mode"
      task :start do
        hive.assets.read
        hive.standalone!
      end

      desc "executes scripts"
      task :script do
        hive.assets.read
        hive.set_enviroment
        script = ENV["SCRIPT"]

        abort "what script to run? use SCRIPT=foo" unless script
        unless script.include?(".")
          script = "#{script}.rb"
        end

        script_path = hive.app_root("script", script)
        load script_path
      end

    end
  end

  namespace :klangwolke do
    namespace "tunnel" do
      PORT = ENV["LOCAL_PORT"] || 7000
      desc "Start a reverse tunnel from FACEBOOK_CONFIG['host'] to localhost:#{PORT}"
      task "start" do
        puts "Tunneling #{FACEBOOK_CONFIG['host']}:#{FACEBOOK_CONFIG['port']} to 0.0.0.0:#{PORT}"
        exec "ssh -p 22022 -nNT -g -R *:#{FACEBOOK_CONFIG['port']}:0.0.0.0:#{PORT} #{FACEBOOK_CONFIG['host']}"
      end

      desc "Check if reverse tunnel is running"
      task "status" do
        if `ssh #{FACEBOOK_CONFIG['host']} netstat -an |
        egrep "tcp.*:#{FACEBOOK_CONFIG['port']}.*LISTEN" | wc`.to_i > 0
          puts "Seems ok"
        else
          puts "Down"
        end
      end
    end
  end
end


task :delete_image do
  env_hive = ENV["BEEHIVE"]

  hive = Hives[env_hive.to_s.downcase.to_sym]
  hive.require_enviroment!
  hive.set_enviroment
  cat = ENV["CAT"]
  imghash = ENV["IMG"]
  abort "no categorie given (CAT)" unless cat
  abort "no imghash given (IMG)" unless imghash

  path = hive.media_path("images", cat)


  Find.find(path) do |file|
    file_hash = File.basename(file).split(".").first
    next if file_hash != imghash
    FileUtils.rm(file, :verbose => true)
  end

end


task :import_images do
  Hives[:dir].require_enviroment!
  Hives[:dir].set_enviroment

  targets = %w(direct sidebar utils)

  targets.each do |target|
    tcdir = "/home/mit/Source/trailercamp/APPS/dogs/app/public/images/auto/#{target}"

    irf = Helper::ImageResize
    tfiles = Dir.glob(tcdir + "/orginal_*.*").map{ |f| File.readlink(f) }

    target_dir = Hives[:dir].media_path("images", "categories", target)

    tfiles.each do |tf|
      fn = PluginMediaController.safe_file(tf, File.open(tf, 'rb'), File.join(target_dir, 'original'))

      new_file = File.join(target_dir, 'original', fn)
      Helper::ImageResize::ImageResizeFacility.new{
        resize(new_file)
      }.start(:thumbnail, :medium, :sidebar, :big)
    end
  end

end

task :fix_calendar_paths do
  Hives[:dir].require_enviroment!
  Hives[:dir].set_enviroment

  mp = Hives[:dir].media_path("events")

  Find.find(mp) do |file|
    if File.extname(file) == ".yaml"
      newfile_ary = File.readlines(file).dup

      newfile_ary.map!{ |nf|
        nf = nf.gsub(/beehives\/dir\//, "")
        nf
      }
      p File.open(file, "w+"){ |fp| fp.write(newfile_ary.join)}
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
