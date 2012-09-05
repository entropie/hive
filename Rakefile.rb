#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require "lib/hive.rb"
include Hive

task :test_assets do
  hive = (ENV["HIVE"] or "test").to_sym

  Queen::hives.load(hive)
  hive = Queen::hives[hive]

  hive.assets.read

  #p hive.assets.beehive_specific

  pp hive.assets.config.port
end


task :start do
  hive = (ENV["HIVE"] or "test").to_sym

  Queen::hives.load(hive)
  hive = Queen::hives[hive]
  hive.assets.read
  
  #p 1
  #p hive.config.port
  #p hive.stylesheet_for_app
  hive.standalone!
end

namespace :beehives do

  Hives = Queen::hives.load
  include Queen
  include Term::ANSIColor

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

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
