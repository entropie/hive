#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class PluginAuthController < QueenController

  map "/p/auth"

  before(:login){ redirect '/' if logged_in? }
  after (:login){ redirect request[:r] if logged_in? }

  def login
    if request.post?
      request[:password] = Digest::SHA1.hexdigest(request[:password])
      user_login(request.subset(:username, :password))
    end
  end

  def register
  end

  def logout
    session.delete(:USER)
    redirect(request[:r] || "/")
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
