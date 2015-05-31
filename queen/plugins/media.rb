#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class PluginMediaController < QueenController
  map "/p/media"

  layout :nil
  engine :none

  provide(:json, :type => 'application/json') do |action, body|
    action.layout = nil
    body.to_json
  end

  def upload
    opts = { }

    if request.post?
      image =
        self.class.
        upload(beehive,
               request[:file],
               beehive.media_path("images"),
               opts)

      redirect PluginMediaController.r(:img, image)
    end
  end

  # FIXME:
  # def img(*fragments)
  #   file = File.join(beehive.media_path("images"), *fragments)
  #   response.header['Content-Type'] = Rack::Mime.mime_type(File.extname(file))
  #   response.body = File.open(file){|f| f.read }
  # rescue
  #   response.status = 404
  # end

  def resize(*fragments)
    file = File.join(beehive.media_path(*fragments))

    Helper::ImageResize::ImageResizeFacility.new(:path => File.dirname(File.dirname(file))) {
      resize(file)
    }.start(:thumbnail, :medium, :sidebar, :big)

    redirect request[:redirect]
  end

  # FIXME:
  def self.safe_file(name, tempfile, target_path, rename = true, filename = nil)
    fp = File.open(tempfile.path, 'rb').read

    if rename
      filename ||= "#{Digest::SHA1.hexdigest(fp)}#{File.extname(name)}"
    end

    adir = ""
    sdir = File.join(adir, filename.downcase).gsub(/^\//, '')

    FileUtils.mkdir_p(target_path, :verbose => true)
    FileUtils.cp(tempfile.path, File.join(target_path, sdir), :verbose => true)
    sdir
  end

  def self.upload(beehive, filehandle, target_path, opts = { })
    safe_file(filehandle[:filename], filehandle[:tempfile], target_path)
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
