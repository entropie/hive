#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class MainController < QueenController

  map "/"

  def index
    "hello from #{beehive.identifier}"
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
