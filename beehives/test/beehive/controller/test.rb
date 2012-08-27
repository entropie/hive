#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class TestController < QueenController

  map "/test"

  def index
    p Ramaze.options.roots
    p Ramaze.options.views
    p Ramaze.options.publics
    "Hallo from test!"
  end

  def lala
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
