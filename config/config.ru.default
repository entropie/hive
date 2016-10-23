require "../../lib/hive.rb"

identifier = File.expand_path(__FILE__).split("/")[-2].to_sym

Hive::Queen::hives.load( identifier )
beehive = Hive::Queen::hives[ identifier ]
beehive.assets.read
beehive.start!(:started => true, :mode => :live)

run Ramaze

