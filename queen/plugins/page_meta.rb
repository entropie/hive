module PageMeta


  Plugins.set_plugin_defaults_for(self, {
                                    :attachment_path      => "site title",
                                    :title_str            => "%s &mdash; %s",
                                    :site_name            => "",
                                    :vitrine_image        => "",
                                    :additional_meta      => { "image:width" => 1024, "image:height" => 768, :type => :article }
                                  })

 
 
  class MetaElements

    include PageMeta

    def page_title
      ""
    end

    def title(t = "")
      if t and t.size > 0
        ::PageMeta.config[:title_str] % [t, ::PageMeta::config[:site_name]]
      else
        ::PageMeta::config[:site_name]
      end
    end

    def _title(s = "")
      title(s)
    end
    
    def page_title
      ::PageMeta::config[:site_name]
    end
    
    def url
      ""
    end

    def vitrine_image(*args)
      ::PageMeta::config[:vitrine_image]
    end
  end


  def _title
    ""
  end

  def _title(str = nil)
    ::PageMeta.config[:title_str] % [page_title, ::PageMeta::config[:site_name]]
  end

  def _url
    respond_to?(:permalink) ? permalink : url
  end

  def _image
    vitrine_image(:big)
  end

  def _description
    respond_to?(:short_description) and short_description or ::PageMeta.config[:site_desc]
  end

  def to_meta
    pm = Facebook.new(:title => _title, :url => SchwelleController::URL(_url.to_s), :site_name => ::PageMeta.config[:site_name], :image => SchwelleController::URL(_image.to_s), :description => _description, :type => "article")
    pm.to_html
  end
  

  class Meta

    class Entry

      attr_reader :property, :value, :prefix

      def initialize(prop, val, prfx = "")
        @property, @value, @prefix = prop, val, prfx
      end

      def tag
        "<meta property='%s' content='%s' %s/>"
      end

      def to_html
        tag % [@prefix+property.to_s, value, ""]
      end
    end

    def prefix
      ""
    end

    def initialize(hash)
      @entries = []
      hash.each_pair do |k,v|
        @entries << Entry.new(k, v, prefix)
      end
    end

    def to_html
      @entries.inject("") do |m, e|
        m+=e.to_html + "\n"
      end
    end

  end

  class Facebook < Meta
    def prefix
      "og:"
    end

    def initialize(hash)
      super(hash.merge(::PageMeta.config[:additional_meta] || {}))
    end

  end
  
end
