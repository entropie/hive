require "../../../lib/hive.rb"

include Hive
identifier = File.expand_path(__FILE__).split("/")[-3].to_sym

Queen::hives.load( identifier )
beehive = Queen::hives[ identifier ]
beehive.assets.read
beehive.standalone!
