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
  
  # Compass.configuration do |config|
  #   config.project_path = Queen::BEEHIVE.app_root,
  #   config.css_dir = Queen::BEEHIVE.app_root("view", "css")
  #   config.sass_dir = "view/"
  #   config.images_dir = "public/images"
  #   config.http_path = "/"
  #   config.http_images_path ="/images"
  #   config.http_stylesheets_path = "/css"
  #   config.http_javascripts_path = "/javascripts"
  #   config.output_style = :compact
  # end
  # trait[:sass_options] = Compass.configuration.to_sass_engine_options

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
