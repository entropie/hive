#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#


# FIXME: stub for now
class User
  USERS = {
    'entropie'    =>  Digest::SHA1.hexdigest('test')
  }

  def self.authenticate(h)
    USERS[h["username"]] == Digest::SHA1.hexdigest(h["password"]) and h
  end
end

class QueenController < Ramaze::Controller

  extend        Queen

  engine        :Haml #config.engine
  layout        config.layout

  helper        :user

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
