#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class SassController < Ramaze::Controller
  map             "/css"
  provide         :css, :Sass
  engine          :Sass
end


=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
