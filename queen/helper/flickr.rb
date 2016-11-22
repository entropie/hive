#FlickRaw.api_key       = "abc"
#FlickRaw.shared_secret = "def"

module Hive
  module Helper
    module Flickr

      class Photo

        class Variant < Struct.new(:label, :width, :height, :source)
        end

        def self.find(fid, force = false)
          file = File.join(Queen::BEEHIVE.media_path, "flickr", "#{fid}.yaml")
          photo = nil
          if File.exist?(file)
            photo = YAML.load(File.readlines(file).join)
            if force
              photo.clear rescue
              photo = nil
            else
              return photo
            end
          end
          photo = new(fid)
          photo.cache_if_needed!
          photo
        end
        
        def initialize(fid)
          @fid = fid.to_i
        end

        def image
          unless @image
            puts "> FI: reading info for #{@fid}"
            @image = flickr.photos.getInfo(:photo_id => @fid)
          end
          @image
        end


        def orientation
          sp = sizes(:large)
          if sp.width >= sp.height then :x else :y end
        end

        def info
          image
        end

        def sizes(which = nil)
          @sizes ||=
            begin
              s = flickr.photos.getSizes(:photo_id => @fid)
              s.map do |ps|
                next if ps["label"].include?(" ")
                lbl = ps["label"].downcase.to_sym
                Variant.new(lbl, ps["width"].to_i, ps["height"].to_i, ps["source"])
              end
            end.compact

          if which
            return @sizes.select{|v| v.label == which}.first
          end
          @sizes
        end

        def url
          @url ||= FlickRaw.url_photopage(image)
        end

        def author
          image["owner"]["username"]
        end

        def profile_url
          @profile_url ||= FlickRaw.url_profile(image)
        end

        def description=(obj)
          @description = obj
        end

        def description
          @description ||= image["description"]
          if not @description or @description.to_s.strip.empty?
            @description = nil
          end
          @description
        end

        def title
          image["title"]
        end

        def path
          File.join(Queen::BEEHIVE.media_path("flickr"), "#{@fid}.yaml")
        end

        def clear
          FileUtils.rm(path)
        rescue
          true
        end
        
        # [:square, :thumbnail, :small, :medium, :large, :original]
        def to_html(what)
          raise "deine mama" unless what.kind_of?(Symbol)
          v = sizes(what)

          str = %Q|
<div class="flickr-image-block flickr-image-block-%s">
  <div class="flickr-image-photo">
    <img class="img-rounded" src="%s" title="%s"  data-sr="enter bottom, vFactor 0.3, scale up 20%%" />
  </div>

  <div class="flickr-image-sub">
    <div class="flickr-image-description">
      <a href="%s">%s</a>  
    </div>
    <div class="flickr-image-author">
      <a href="%s">%s</a>
    </div>
  </div>
</div>
|
          str % [what, v.source, title, url, description||title, profile_url, author]
        rescue
          as = to_html(sizes[-2].label)
        end

        def cache_if_needed!(force = false)
          if not File.exist?(path) or force
            clear
            sizes
            image
            description
            url
            profile_url
            File.open(path, "w+") do |fp|
              puts "> FI: writing #{path} "
              fp.puts(YAML::dump(self))
            end
          end
        end
      end

      def FI(fid, size = :large, desc = nil)
        size = :large if not size or size.to_s.strip.empty?
        size = size.to_sym
        i = Helper::Flickr::Photo.find(fid)
        i.description = desc if desc
        i.to_html(size)
      end

      def FIS(fid, size = :medium, desc = nil)
        size = :medium if not size or size.to_s.strip.empty?
        size = size.to_sym
        i = Helper::Flickr::Photo.find(fid)
        i.description = desc if desc
        sizes = i.sizes(size).source
      rescue
        URL("/img/og-image.jpg")
      end
    end
  end
end
