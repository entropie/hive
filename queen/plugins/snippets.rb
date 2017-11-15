module Snippets

  Plugins.set_plugin_defaults_for(self, {
                                    :attachment_path      => "snippets",
                                    :admin_controller     => proc{AdminController}
                          })
  
  def self.[](obj)
    read unless @snippets
    r = snippets[obj]
    return ErrorSnippet.new(obj) unless r
    r
  end
  
  def self.attachment_path(*args)
    Queen::BEEHIVE.media_path(::Snippets.config[:attachment_path], *args)
  end

  def self.read
    puts "-> Loading snippets"
    tmp = []
    Dir.glob(attachment_path + "/*").each do |snippet_file|
      tmp << snippets.from_file(snippet_file)
    end
    tmp.sort_by{|s| s.identifier.to_s }.each do |s|
      snippets << s
    end
    snippets
  end

  def self.snippets
    @snippets ||= Snippets.new
  end

  def self.clear
    @snippets = nil    
  end

  def self.all
    read unless @snippets
    snippets
  end

  def self.create(ident, kind = RCSnippet)
    sn = snippets.create(ident, kind)
    snippets << sn
    sn
  end

  class Snippets < Array
    def create(ident, kind)
      kind.new(ident)
    end

    def from_file(snippet_file)
      Snippet.select_snippet_class_for_file(snippet_file).new(Snippet.identifier_from_filename(snippet_file))
    end

    def <<(obj)
      puts "  > #{obj.identifier} (#{obj.path})"
      super(obj)
    end

    def [](obj)
      select{|s| s.identifier == obj}.first
    end
  end

  module GalleryExtension
    def gallery
      Gallery::Galleries.by_slug("website")
    end

    def images
      gallery.images
    end
  end

  module SnippetExtension
    def snippet(str)
      SchwelleController.render_snippet(str)
    end
  end
  
  class Snippet

    include GalleryExtension
    include SnippetExtension
    
    attr_reader :identifier

    def self.snippet_variants
      @snippet_variants ||= []
    end

    def self.inherited(obj)
      snippet_variants << obj
    end
    
    def initialize(identifier)
      @identifier = identifier
    end

    def write(contents)
      @value = contents
      File.open(path, "w+") {|fp|
        puts "writing to #{path}"
        fp.puts(contents)
      }
    end

    def value
      @value = File.readlines(path).join
    end

    def self.identifier_from_filename(fn)
      File.basename(fn).split(".").first.to_sym
    end

    def filename_from_identifier(ident, extname)
      "%s%s" % [ident, extname]
    end
    
    def path
      ::Snippets.attachment_path(filename_from_identifier(identifier, self.class.extname))
    end

    def exist?
      File.exist?(path)
    end

    def self.select_snippet_class_for_file(file)
      r = snippet_variants.select{|sc| sc.extname == File.extname(file)}.first
      unless r
        ErrorSnippet
      end
      r
    end

    def render
      "<div class='snippet error'>#{identifier}</div>"
    end

    def url
      ac = ::Snippets.config[:admin_controller].call
      ac.r(:snippets, identifier)
    end

    def edit_url(*args)
      ac = ::Snippets.config[:admin_controller].call
      ac.r(:snippets, :edit, identifier, *args)
    end

    def edit_class
      "text"
    end

    def tag
      "<span class='snippet' data-id='#{identifier}'>%s</span>"
    end
  end

  class ErrorSnippet < Snippet
    def self.extname
      ""
    end
    
  end
  
  class HAMLSnippet < Snippet
    def self.extname
      ".haml"
    end

    def render
      engine = Haml::Engine.new(value)
      tag % engine.render(self)
    rescue
      "<span class='snippet snippet-error'>Fehler beim rendern von #{identifier}: #{$!}</span>"
    end

    def edit_class
      "textarea"
    end
  end

  class RCSnippet < Snippet
    def self.extname
      ".markdown"      
    end

    def tag
      "<span class='markdown_snippet' data-id='#{identifier}'>%s</span>"
    end

    def render
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(extensions = {}))
      tag % markdown.render(value)[3..-6]
    end
  end
end
