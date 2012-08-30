#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class TestController < QueenController

  map "/test"

  def index
  end

  def lala
  end

  def _ajax
    Faker::Lorem.paragraph
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
