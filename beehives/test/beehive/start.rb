#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require "../../../lib/hive.rb"

include Hive
identifier = File.expand_path(__FILE__).split("/")[-3].to_sym

Queen::hives.load( identifier )
Queen::hives[ identifier ].start

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
