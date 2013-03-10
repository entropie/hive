#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class SassController < Ramaze::Controller
  map             "/css"
  provide         :css, :Sass
  engine          :Sass


  #helper :cache

  trait :sass_options => {
    :style => :compressed,
    :load_paths => [Queen::BEEHIVE.app_root("view", "css")],
    :cache_location => Queen::BEEHIVE.app_root("../tmp/sass-cache")
  }

  def application
    beehive = Queen::BEEHIVE

    str = ""
    beehive.config.css.each { |mt, file|
      next if file.include?(".min") or file.include?("application")
      str << %Q'@import "#{file.gsub("css", "sass")}"\n'
    }
    str
  end

  #cache_action :method => 'application'
end


=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
