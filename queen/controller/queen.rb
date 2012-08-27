#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class QueenController < Ramaze::Controller

  extend        Queen

  engine        :Haml #config.engine
  layout        config.layout

  def stylesheet_for_app
    Queen::BEEHIVE.stylesheet_for_app
  end

  def javascript_for_app
    Queen::BEEHIVE.javascripts_for_app
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
