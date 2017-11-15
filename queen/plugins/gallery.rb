# coding: utf-8
module Gallery


  Plugins.set_plugin_defaults_for(self, {
                                    :attachment_path      => "gallery",
                                    :http_path          =>    "/assets/gallery",
                                    :blog_controller    =>    proc { BlogController },
                                    :admin_controller   =>    proc { AdminController },
                                    :gallery_controller =>    proc { GalleryController },
                                    :metadata_defaults  =>    {
                                      :public           =>    false
                                    },
                                    :image_metadata_defaults  =>    {
                                      :public           =>    false
                                    },
                                    :resize_methods     =>    [:thumbnail, :medium, :sidebar, :big, :panorama, :blurred]
                                  })

  def self.to_slug(str)
    str.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end


  class Galleries < Hash

    def self.root(*args)
      retpath = File.join(Queen::BEEHIVE.media_path( ::Gallery.config[:attachment_path] ), *args)
      retpath
    end


    def self.all
      Dir.glob("#{root}/*").map{|path|
        g = Gallery.new
        g.path = File.basename(path)
        g.metadata
        g
      }
    end

    def self.by_slug(slug)
      all.dup.select{|g| g.slug == slug }.first
    end

    def self.by_short_identifier(short_identifier)
      all.dup.select{|g| g.short_identifier == short_identifier }.first
    end

    class Gallery

      attr_accessor :path

      class Metadata

        attr_accessor :file, :title, :short_identifier

        def data
          (@data ||= {})
        end

        def [](obj)
          data[obj]
        end

        def []=(obj, val)
          data[obj, val]
        end
        
        def initialize(file)
          @file = file
        end

        def write!
        end

        def self.read_from(path)
          new(path).read
        end

        def metadata_defaults
          ::Gallery.config[:metadata_defaults]
        end

        def write_if_needed
          unless File.exist?(file)
            update(metadata_defaults)
          end
        end

        def write!
          File.open(file, "w+"){|fp|
            puts ">>> updateing #{file}"
            fp.puts(to_yaml)
          }
        end

        def read
          write_if_needed
          YAML::load(File.readlines(file).join)
        end

        def update(hash)
          hash.each_pair do |md, mv|
            instance_variable_set("@#{md}", (mv.kind_of?(Proc) ? mv.call : mv))
          end
          write!
        end

      end

      class ImageMetadata < Metadata
        def metadata_defaults
          ::Gallery.config[:image_metadata_defaults]
        end
      end

      class Image

        attr_reader :path, :gallery

        def initialize(path, gallery)
          @path, @gallery = path, gallery
        end

        def subimg(*p)
          File.join(path, *p, "#{ident}#{extname}")
        end

        def extname
          File.extname(Dir.glob("#{path}/*").select{|f| File.file?(f) and File.extname(f) != ".yaml"}.first)
        end

        def ident
          File.basename(path)
        end

        def real_path(which = "big")
          subimg(which)
        end

        def url(which = "big")
          File.join(::Gallery.config[:http_path], gallery.slug, ident, which.to_s, "#{ident}#{extname}")
        end

        def permalink
          ::Gallery.config[:gallery_controller].call.r(:image, gallery.slug, ident)
        end

        def metadata_file
          File.join(@path, "metadata.yaml")
        end

        def short_identifier
          metadata.short_identifier || ident
        end

        def set(what, value)
          metadata.update(what.to_sym => value)
        end

        def title
          metadata.title || "no title"
        end
        
        def metadata
          @metadata ||= ImageMetadata.read_from( metadata_file )
        end

        def to_html(s = "big")
          "<img class='img-rounded' data-sr='enter bottom, vFactor 0.3, scale up 20%%' src='%s' alt='%s'/>" % [url(s), title]
        end
        
      end

      class DummyImage
        def initialize(obj)
          @obj = obj
        end
        
        def url
          "holder.js/300x200" % [@obj]
        end

        def to_html(*args)
          "<img class='img-rounded' data-sr='enter bottom, vFactor 0.3, scale up 20%%' src='%s' alt='dummy'/>" % url
        end
      end

      class Images < Array
        def [](obj)
          str = obj.to_s
          r = select{|a| a.short_identifier == str}.first
          unless r
            return DummyImage.new(obj)
          end
          r
        end
      end

      def set(what, value)
        metadata.update(what.to_sym => value)
      end

      def find(oslug)
        read.select{|r|
          r.ident == oslug
        }.first
      end

      def slug
        @slug ||= File.basename(path)
      end

      def human_title
        metadata.title || "Unbenanntes album"
      end

      def path=(args)
        @path = Galleries.root(args)
      end

      def path(*args)
        File.join(@path, *args)
      end

      def metadata
        @metadata ||= Metadata.read_from( path("metadata.yaml") )
      end
      
      def initialize
      end

      def create(cpath)
        create_or_update(args)
      end

      def create_or_update(cpath)
        g = Gallery.new
        g.path = cpath
        unless File.directory?(g.path)
          FileUtils.mkdir_p(g.path, :verbose => true)
        end
        g.metadata.write_if_needed
        g
      end

      def add(imagepath)
        dig = Digest::SHA256.file(imagepath).to_s
        target = "%s%s" % [dig, File.extname(imagepath).downcase]
        target_path = path(dig)
        FileUtils.mkdir_p(path(dig))

        FileUtils.cp(imagepath, File.join(target_path, target), :verbose => true)
        
        ts = [:thumbnail, :medium, :sidebar, :big, :blurred, :panorama]

        Helper::ImageResize::ImageResizeFacility.new(:path => File.join(target_path)) {
          resize(File.join(target_path, target))
        }.start(*ts)
      end
      
      def read
        r = Dir.glob("#{path}/*").map{|spath|
          if File.basename(spath).size == 64
            Image.new(spath, self)
          else
            nil
          end
        }.compact
        Images.new(r)
      end

      def images
        read
      end

      def contents
        read
      end

      def vitrine_image(str = "")
        contents.sort_by{rand}.first.url
      end

      def edit_url
        ::Gallery.config[:admin_controller].call.r(:gallery, slug)
      end

      def url
        ::Gallery.config[:gallery_controller].call.r(:show, slug)
      end

      def link
        "<a href='%s'>%s</a>" % [url, human_title]
      end

      def page_title
        "Gallery: %s" % human_title
      end
    end
  end
  
end
