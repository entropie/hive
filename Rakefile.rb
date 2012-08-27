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

  puts 
  pp hive.assets.config.port
end

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
