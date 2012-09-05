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

  include       Queen
  extend        Queen

  engine        :Haml #config.engine
  layout(config.layout) { !request.xhr? }

  helper        :user

  provide(:json, :type => 'application/json') do |action, body|
    body.to_json
  end

  provide(:txt, :type => 'text/plain') do |action, body|
    body.to_s
  end


  def self.action_missing(path)
    return nil if path == '/E404'
    try_resolve('/E404')
  end

  def E404
    "404"
  end

  private

  def stylesheets_for_app
    Queen::BEEHIVE.stylesheets_for_app
  end

  def javascripts_for_app
    Queen::BEEHIVE.javascripts_for_app
  end

  def beehive_render_file(file, opts = { })
    render_file(File.join(BEEHIVE.view_path, file), opts)
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
