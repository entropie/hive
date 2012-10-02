#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require "lib/hive.rb"
include Hive

namespace :beehives do

  Hives = Queen::hives.load
  include Queen
  include Term::ANSIColor

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

    end
  end
end


task :delete_image do
  hive = Hives[:dir]
  hive.require_enviroment!
  hive.set_enviroment
  cat = ENV["CAT"]
  imghash = ENV["IMG"]
  abort "no categorie given (CAT)" unless cat
  abort "no imghash given (IMG)" unless imghash

  path = hive.media_path("images", "categories", cat)


  Find.find(path) do |file|
    file_hash = File.basename(file).split(".").first
    next if file_hash != imghash
    FileUtils.rm(file, :verbose => true)
  end

end

task :import_images do
  Hives[:dir].require_enviroment!
  Hives[:dir].set_enviroment

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

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
