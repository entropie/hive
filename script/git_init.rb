#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require File.join(File.dirname(File.expand_path(__FILE__)), "../lib/hive.rb")

identifier = ARGV.join.strip

dir = File.join(File.expand_path("~/Source/hive/beehives"), identifier)

abort "need identifier of the beehive" if not identifier or identifier.empty?
abort "beehive #{dir} !exist" unless File.exist?(dir)

def sh(cmd)
  puts "> running #{cmd}"
  puts `#{cmd}`
end

sh "ssh mc 'mkdir ~/Source/beehives/#{identifier} && cd ~/Source/beehives/#{identifier} && git init --bare'"

Dir.chdir(dir) do
  sh "git init"
  sh "git remote add origin ssh://mc/home/mit/Source/beehives/#{identifier}"
  sh "git add ."
  sh "git commit -am initial"
  sh "git push --set-upstream origin master"
end

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
