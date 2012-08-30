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
    USERS[h["username"]] == h["password"] and h["username"]
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

  def current_user
    session[:USER][:credentials]["username"] # FIXME: stub
  rescue
    nil
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
