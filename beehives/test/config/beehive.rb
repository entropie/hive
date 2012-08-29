#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

setup do |c|
  c.port        = 9000

  c.css         = [
                   [:screen, "bootstrap.min.css"], [:screen, "test.css"]
                  ]

  c.js          =   ["jquery.min.js", "application.js"]

end

=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
