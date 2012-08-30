#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class AuthController < QueenController

  map "/auth"

  before(:login){ redirect '/' if logged_in? }
  after (:login){ redirect request[:r] if logged_in? }

  def login
    if request.post?
      user_login(request.subset(:username, :password))
    end
  end

  def logout
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
