#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#


# FIXME: stub for now
class QueenController < Ramaze::Controller

  include       Hive

  include       Queen
  extend        Queen

  engine        :Haml
  # trait         :haml_options => {
  #   :encoding  => "utf-8"
  # }

  layout(config.layout) { !request.xhr? }

  helper        :user

  provide(:json, :type => 'application/json') do |action, body|
    body.to_json
  end

  provide(:txt, :type => 'text/plain') do |action, body|
    body.to_s
  end

  def rpath
    request.env["REQUEST_URI"]
  end

  def active_link(url, text)
    begin
      if rpath == url or rpath.split("/")[0..2].join("/") == url
        active_link = "active"
      # elsif (nurl = "/#{rpath.split("/")[1]}") == "/a"
      #   active_link = "active" if url == nurl
      elsif rpath =~ /^\/blog/ and url == "/blog"
        active_link = "active"
      end
    rescue
      active_link = ""
    end

    "<a href='#{url}' class='#{active_link.nil? ? "" : "active"}'>#{text}</a>"
  end

  def self.action_missing(path)
    return nil if path == '/E404'
    try_resolve('/E404')
  end

  def E404
    "404"
  end

  private

  def beehive
    @app ||= Queen::BEEHIVE
  end

  def stylesheets_for_app
    Queen::BEEHIVE.stylesheets_for_app
  end

  def javascripts_for_app
    Queen::BEEHIVE.javascripts_for_app
  end

  def beehive_render_file(file, opts = { })
    render_file(File.join(BEEHIVE.view_path, file), opts)
  end

  def plugin_render_file(plugin, file, opts = { })
    render_file(Source.join("queen", "view", "p", file), opts)
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
