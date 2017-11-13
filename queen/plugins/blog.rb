# coding: utf-8
#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module Blogs

  Plugins.set_plugin_defaults_for(self, {
                                    :template_path      =>    "blog/styles",
                                    :attachment_path    =>    "blog/attachments",
                                    :http_attachment_path =>  "/assets/blog/attachments",
                                    :blog_controller    =>    proc { BlogController },
                                    :admin_controller   =>    proc { AdminController },
                                    :resize_methods     =>    [:thumbnail, :medium, :sidebar, :big, :panorama, :blurred]
                                  })

  module FileWriter
    include FileUtils

    def write_to(file, h = "w+", &blk)
      debug "writing to #{file}"
      reload!
      File.open(file, h, &blk)
    end
  end


  module PostAncestors
    def before(logged_in)
      gps = group.posts(logged_in)
      all = posts(logged_in).map(&:post)
      global_index = all.index(self)
      if in_group?
        if (ind = gps.index(self)) > 0
          return gps[gps.index(self)-1]
        else
          return all[global_index-1]
        end
      else
        if pst = all[global_index-1]
          return pst
        end
      end
    end

    def after(logged_in = false)
      gps = group.posts(logged_in)
      all = posts(logged_in).map(&:post)
      all_posts_size = all.size
      global_index = all.index(self)

      if in_group?
        if (ind=gps.index(self)) < gps.size-1
          return gps[ind+1]
        else
          return all[global_index+1]
        end
      else
        if pst = all[global_index+1]
          return pst
        end
      end
    end
  end

  include Helper::Flickr

  def self.html_truncate(html, url, length, o = true)
    html_string = TruncateHtml::HtmlString.new(html)
    omis = "<span style='color:silver'>[...]</span>"
    wb = /([\.\?\!])/
    TruncateHtml::HtmlTruncator.new(html_string, :length => length, :omission => "", :word_boundary => wb).truncate
  end

  def self.templates
    files = Dir.glob( File.join(Queen::BEEHIVE.view_path, config[:template_path]) + "/*.haml" )
    files.map{ |f| File.basename(f)[1..-6] }.sort
  end

  def self.default_template
    "big"
  end

  def self.template_path(template)
    if template[0..0] != "_"
      template = "_#{template}"
    end
    "%s/%s" % [config[:template_path], "#{template}.haml"]
  end

  def self.with_markdown(str, r = Redcarpet::Render::HTML)
    markdown = Redcarpet::Markdown.new(r, :tables => true, :footnotes => true)
    markdown.render(str)
  end

  def self.truncate(str, url, n = 500)
    retstr = html_truncate(str, url, n)
  end

  def slug
    to_slug
  end

  def self.to_slug(str)
    str.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def self.path
    "blog"
  end

  def self.make_path(*args)
    args.join("-")
  end

  def self.[](meta)
    post = Post.new(meta.filename)
    post.metadata = meta
    post
  end

  def reload!
    debug "reloading posts"
    DB.replace([])
    posts
  end

  def posts(logged_in = false)
    if DB.empty?
      DB.replace(Posts.new)
    end
    @db = DB
    if not logged_in
      @db = @db.select{|p| p.post.published? }
    else
      @db
    end
  end

  def random_post
    posts.sort_by{rand}.first
  end

  def find_by(arg, logged_in = false)
    posts(logged_in).select{ |pst| pst.post.slug == arg }.first.post
  rescue
    nil
  end

  def find_by_tags(logged_in, *arg)
    posts(logged_in).select{ |pst| pst.post.tags.any?{|t| arg.include?(t) } }.map{|p| p.post }
  end

  class Posts < Array

    attr_reader :logged_in

    def initialize
      read
    end

    def read
      replace Database.read_for # do
    end

    def relative_path(*args)
      File.join("blog", *args)
    end
  end

  class Groups
    def initialize
      @groups = Hash.new { |hash, key| hash[key] = Group.new(key) }
    end

    def [](obj)
      @groups[obj]
    end

    def each(&blk)
      @groups.each do |gn, gv|
        yield gv
      end
    end

  end

  class Group < Posts
    attr_reader :name
    def initialize(name)
      @name = name
    end

    def name_sanitized
      @name
    end

    def previous
      self[self.index(self)-1]
    end

    def next
      self[self.index(self)+1]
    end

    def size(logged_in = false)
      posts(logged_in).size
    end

    def name_html(logged_in = false, active = false)
      act = active ? " active" : ""
      %Q'<a data-posts="#{size(logged_in)}" class="group-link#{act} btn btn-success btn-xs" href="#{Blogs.config[:blog_controller].call.r(:group, name_sanitized)}"><span class="glyphicon glyphicon-list-alt"></span> #{@name}</a>'
    end

    def posts(logged_in = false, &blk)
      ret = self.dup.select{|pst|
        if logged_in
          true
        elsif pst.published?
          true
        else
          false
        end
      }
    end

    def sorted(logged_in = false, &blk)
      posts(logged_in).sort_by{ |pst| pst.date }.reverse.each(&blk)
    end

    def to_hash
      {:name => name }
    end
  end


  class Filter

    attr_reader :post
    
    class NokogiriFilter
      def initialize(html)
        @content = Nokogiri::HTML.fragment(html)
      end
      def setup(post)
        @content.to_html
      end
    end

    class EngineCache < NokogiriFilter

      attr_reader :written, :content

      def filename(str)
        [self.class.to_s.split("::").last.downcase, str].join("_") + ".html"
      end

      def written?
        @written
      end

      def setup(post)
        target_file = post.attachment_path(filename("post"))
        unless File.exist?(target_file)
          @written = true
          ret = super
          FileUtils.mkdir_p(File.dirname(target_file), :verbose => true)
          File.open(target_file, "w+"){|fp|
            fp.puts(ret)
          }
          @content = ret
        else
          @content = File.readlines(target_file).join
        end
        self
      end
    end

    class ImageFilter
      def initialize(html)
        @html = html
      end

      def filename(str)
        [self.class.to_s.split("::").last.downcase, str].join("_") + ".html"
      end

      def setup(post)
        @html
      end

    end

    class FlickrFilter < ImageFilter
      def setup(post)
        @html.gsub!(/(\[flickr: (\d+) ?(.*))\]/) do |match|
          flickrid = $2.to_i
          rest = $3
          rest = :large unless rest or rest.strip.empty?
          FI(flickrid, rest.to_sym)
        end
        @html
      end
    end

    class FlickrGroup < ImageFilter

      def setup(post)
        @html.gsub!(/(\[flickgr: (.*)\])/) do |match|
          flickrids = *$2.split(" ").map(&:to_i)
          ret = "<div class='flickr-group-box'>%s</div>"
          ret % flickrids.map{|fid| FI(fid, :small) }.join
        end
        @html
      end
      
    end

    # class SideComments < NokogiriFilter
    #   def setup(post)
    #     @content.css("p, ul, ol").each_with_index do |node, index|
    #       node["data-id"] = index
    #     end
    #     super
    #   end
    # end

    class TopicAnchors < NokogiriFilter
      def setup(post)
        @content.css("h1,h2,h3,h4,h5,h6").each_with_index do |node, index|
          ident = Blogs.to_slug(node.text)
          node["id"] = ident
          #node["data-topic-slug"] = ident
        end
        super
      end
    end

    class Paragraphing < NokogiriFilter
      def setup(post)
        @content.css("p, ul, ol").each_with_index do |node, index|
          node["class"] = "post-text-block"
        end
        super
      end
    end

    class HTMLFilter < Filter
      def apply!
        ret = post.content

        ec = EngineCache.new(ret)
        ec = ec.setup(post)
        if ec.written?
          HTMLFilter.clear!(post)
          ret = Blogs.with_markdown(ret)


          
          ret = FlickrFilter.new(ret).setup(post)
          ret = FlickrGroup.new(ret).setup(post)
          #ret = SideComments.new(ret).setup(post)
          ret = TopicAnchors.new(ret).setup(post)
          ret = Paragraphing.new(ret).setup(post)
          ret = EngineCache.new(ret).setup(post).content
          ret
        else
          ec.content
        end
      end

    end

    def initialize(post)
      @post = post
    end

    def self.clear!(post)
      Dir.glob("#{post.attachment_path}/*.*").each do |f|
        FileUtils.rm(f, :verbose => true)
      end
    end

    def self.apply(what, post)
      HTMLFilter.new(post).apply!
    end
  end

  class Post

    include PostAncestors


    attr_accessor :file, :title, :content, :metadata

    def attachment_path(*args)
      File.join(Queen::BEEHIVE.media_path( Blogs.config[:attachment_path] ), slug, *args)
    end

    def vitrine_image_file
      metadata.image
    end

    def image=(imagepath)
      dig = Digest::SHA1.file(imagepath).to_s
      target = "%s%s" % [dig, File.extname(imagepath).downcase]
      target_path = attachment_path(dig)
      FileUtils.mkdir_p(attachment_path(dig))

      FileUtils.cp(imagepath, File.join(target_path, target), :verbose => true)
        
      ts = Blogs.config[:resize_methods]
      Helper::ImageResize::ImageResizeFacility.new(:path => File.join(target_path)) {
        resize(File.join(target_path, target))
      }.start(*ts)
      metadata.image = target
      metadata.update!
    end

    def slug
      @slug ||= Blogs.to_slug(title)
    end

    def http_attachment_path(*args)
      File.join(File.join(Blogs.config[:http_attachment_path], slug, *args.map(&:to_s)))
    end

    def vitrine_image(version = "", default = "")
      ident = metadata.image.split(".").first
      http_attachment_path(ident, version, vitrine_image_file)
    rescue
      if version and version != ""
        "/img/vitrine-default-#{version}.jpg"
      else
        "/img/vitrine-default.jpg"
      end
    end

    def intro(link = true)
      go_onlink = " <span style='color:silver'>[...]</span>&nbsp;<a href='#{url}'>weiterlesen</a>"
      str = Nokogiri::HTML(to_html).xpath("//p").first.text
      if link
        return str + go_onlink
      end
      str
    end

    def publish!
      src = relative_path
      target = relative_path.gsub(/\/draft\//, "/posts/")
      FileUtils.mv(File.join(Queen::BEEHIVE.media_path(src)),
                   File.join(Queen::BEEHIVE.media_path, target), :verbose => true)
      metadata.filename = target
      metadata.publish!
      Database.reload!
      self
    end

    def unpublish!
      src = relative_path
      target = relative_path.gsub(/\/posts\//, "/draft/")
      FileUtils.mv(File.join(Queen::BEEHIVE.media_path(src)),
                   File.join(Queen::BEEHIVE.media_path, target), :verbose => true)
      metadata.filename = target
      metadata.unpublish!
      Database.reload!
      self
    end

    # FIXME: haha
    def relative_path
      "%s.markdown" % File.join("blog", (published? ? "posts" : "draft"), slug) 
    end

    def published?
      metadata.published?
    end

    def publish_or_unpublish
      if published? then unpublish! else publish! end
    end

    def image?
      metadata.image rescue nil
    end

    def edit_date
      metadata.edit_date
    end

    def in_group?
      not group.name.empty?
    end

    def template
      metadata.template
    end

    def template_path
      Blogs.template_path(template)
    end

    def image(which = "")
      vitrine_image(which)
    end

    def default_path
      Blogs.path
    end

    def initialize(file)
      @file = file
    end

    def ==(obj)
      obj.slug == slug
    end

    def group
      @group ||= Database.groups[metadata.group]
    end

    def title
      @title || metadata.title
    end

    def path
      Queen::BEEHIVE.media_path(metadata.filename)
    end

    def content
      @content ||= File.readlines(path).join
    end

    def to_html
      Filter.apply(:html, self)
    end

    def pid
      @pid ||= Digest::SHA256.hexdigest(slug)
    end

    def to_hash
      {
        :content => content,
        :id      => pid,
        :author  => metadata.author.to_json,
        :tags    => tags,
        :date    => date,
        :edit_date => edit_date,
        :draft   => draft?,
        :group   => group.to_hash,
        :image   => metadata.image,
        :attachment_path => http_attachment_path,
        :slug    => slug,
        :title   => title
      }
    end

    def html_title(active = false, logged_in = true)
      clshsh = ["post-title"]
      clshsh << "active" if active
      clshsh << "draft" if draft? and logged_in
      %Q'<a href="#{url}" class="#{clshsh.join(" ")}">#{title}</a>'
    end

    def url
      Blogs.config[:blog_controller].call.r(slug)
    end

    def edit_url
      Blogs.config[:admin_controller].call.r(:blog, slug)
    end

    def author
      metadata.author.to_html
    end

    def date
      ret = if published?
              metadata.published_date
            else
              metadata.date
            end
      ret
    end

    def basename
      "%s.markdown" % Blogs.to_slug(title)
    end

    def tags
      metadata.tags
    end

    def update!
      metadata.update!
    end

    def draft?
      not metadata.published?
    end

    def publish_or_unpublish_url
      Blogs.config[:blog_controller].call.r(:publish_or_unpublish, slug)
    end

    def upload_url
      Blogs.config[:admin_controller].call.r(:upload, :postslug => slug)
    end

    def delete
      [attachment_path, path, metadata.md_filename].each do |ftd|
        FileUtils.rm_rf(ftd, :verbose => true)
      end
    end
  end

  class Draft < Post
    def publish!
      debug "publishing #{title}"
      metadata.publish!
      update!
    end
  end

  class NewPost < Draft

    include FileWriter

    def title
      @params["title"]
    end

    def content
      @params["content"]
    end

    def default_path
      File.join(super, "draft")
    end

    def initialize(request)
      @params = request.params
      @request = request
    end

    def write(u = Contributors::Anna)
      if title.nil? or title.empty?
        raise "no title"
      elsif content.nil? or content.empty?
        raise "no content"
      end
      bn = File.join(default_path, basename)

      self.metadata = Metadata.new(bn, title)

      metadata.load_if_exist!

      # FIXME:
      self.metadata.author ||= u

      metadata.template  = @params["template"]
      metadata.group     = @params["group"]

      tags = @request[:tags].to_s.split(",")

      metadata.add_tags(*tags)

      write_to(path, "w+"){ |fp|
        fp.write(content)
        Filter.clear!(self)
        metadata.write
      }
      Database.reload!
      self
    end

  end

  module Database
    def self.read_for(&blk)
      debug "reading posts in ... #{Queen::BEEHIVE.media_path(base_path + "/*.yaml")}"
      ret = contents
      ret.sort_by!{ |pst| pst.post.date }.reverse!
      ret.each(&blk) if block_given?
      ret
    end

    def self.groups
      @groups = contents.select{|md| not md.group.strip.empty? }.inject(Groups.new) { |m, md| 
        m[md.group] << md.post
        m
      }
      @groups
    end

    def self.glob(p = Queen::BEEHIVE.media_path(base_path + "/*.yaml"))
      Dir.glob(p)
    end

    def self.clear!
      @__content__ = []
      @groups      = []
    end

    def self.reload!
      clear!
      DB.clear
      contents
    end

    def self.contents
      return to_a if to_a and not to_a.empty?
      clear!
      glob.each do |yml|
        debug "  loading #{File.basename(yml)}"
        self << YAML::load_file(yml)
      end
      to_a
    end

    def self.to_a
      @__content__
    end

    def self.<<(obj)
      (@__content__ ||= []) << obj
    end

    def self.base_path
      File.join("blog", "metadata")
    end
  end

  class Metadata

    include FileWriter

    FIELDS = [:filename, :title, :date, :author, :published_date,
              :tags, :edit_date, :group, :language, :image, :template, :published]

    attr_accessor *FIELDS

    def initialize(*args)
      FIELDS.each do |f|
        instance_variable_set("@#{f}", args[FIELDS.index(f)])
      end
    end

    def load_if_exist!
      if @author.nil? and File.exist?(md_filename)
        fc = YAML::load_file(md_filename)
        FIELDS.each do |f|
          instance_variable_set("@#{f}", fc.send(f))
        end
      end
    end

    def template
      @template || "default"
    end

    def template=(tmpl)
      @template = tmpl
    end

    def group=(grp)
      @group = grp
    end

    def self.normalize_tags(ts)
      ts.map{ |t| t.strip.downcase }.uniq
    end

    def language
      @language ||= "de"
    end

    def post
      @post = Blogs[self]
    end

    def update!
      self.edit_date = Time.now
      write
    end

    def relative_path
      File.join("blog", "metadata", Blogs.to_slug(title)) + ".yaml"
    end

    def add_tags(*inputtags)
      @tags = self.class.normalize_tags(inputtags)
    end

    def published
      @published
    end

    def published?
      filename =~ /\/posts\//
    end

    def publish!
      self.published_date = Time.now
      write
    end

    def unpublish!
      self.published_date = nil
      write
    end

    def md_filename
      Queen::BEEHIVE.media_path(relative_path)
    end

    def write
      t = Time.now
      @date ||= t
      @edit_date = t
      language # to make sure the variable is set for yaml
      write_to(md_filename, "w+") { |fp|
        @db = nil
        t = self
        t.remove_instance_variable(:@db)
        fp.write(t.to_yaml)
      }
    end
  end

end

include Blogs
=begin
Local Variables:
  mode:ruby
  fill-column:70
  indent-tabs-mode:nil
  ruby-indent-level:2
End:
=end
