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

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
