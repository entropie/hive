module Forms

  def self.eval(str, name)
    f = Form.new(name)
    f.eval(str)
    f
  end

  def self.media_file(file)
    n = file.split(".").first
    file = Queen::BEEHIVE.media_path("forms", file)
    eval(File.readlines(file).join, n.to_sym)
  end
  

  class Form
    attr_reader :name, :groups

    attr_accessor :action, :request

    def initialize(name)
      @name = name
      @groups = Formgroups.new(self)
    end

    def params(param = nil)
      if param
        request.params(param)
      end
      request.params
    end
    
    def eval(str)
      Kernel.eval(str, binding)
    end

    def method_missing(m, *rest, &blk)
      fg = Formgroup.new(m, *rest)
      fg.form = self
      if block_given?
        fg.instance_eval(&blk)
      end
      @groups << fg
      fg
    end

    def action
      " action='#{@action}' method='POST' "
    end

    def submit
      "<div class='col'><input type='submit' /></div>"
      
    end

    def captcha
      ReCaptcha.recaptcha_tag
    end
    
    def to_html
      "<form%s name='%s' id='%s'>%s%s%s</form>" % [action, @name.to_s, @name.to_s, @groups.to_html, submit, captcha]
    end

    class Formgroups < Array
      def initialize(form)
        @form = form
      end

      def to_html
        map{|g|  g.to_html }.join
      end
    end

    module MMFormElemts

      attr_accessor :form

      def _group
        @group || self
      end

      
      def method_missing(m, *rest, &blk)
        fe = Formelement.decide(m, *rest, &blk)
        fe.group = _group
        fe.form = form
        if block_given?
          fe.instance_eval(&blk)
        end
        (@elements ||= []) << fe
        fe
      end
    end

    
    class Formgroup

      include MMFormElemts
      
      def initialize(label, desc)
        @label, @desc = label, desc
      end

      def label
        @label
      end

      def to_html
        res = @elements.map{|e|
          e.to_html
        }.join
        "<fieldset><legend>#{@desc}</legend>#{res}</fieldset>"
      end
      
    end

    class Formelement

      attr_accessor :opts, :desc, :group, :ident
      attr_accessor :request_value, :form
      
      def self.decide(m, *args, &blk)
        clz = case m.to_s
              when /^xo_(.*)$/   then    Radio.new($1)
              when /^xx_(.*)$/   then    Checkbox.new($1)
              when /^XO_(.*)$/   then    Select.new($1)
              when /^text_(.*)$/ then    Textarea.new($1)
              else
                if m.to_s[-1] == "?"
                  m = m.to_s[0..-2]
                  r = Radio.new(m)
                  args.push({"1" => "Ja", "0" => "Nein"})
                  r
                else
                  Text.new(m.to_s)
                end
              end
        clz.desc = args.shift
        clz.opts = args
        clz
      end


      def attr
        (@attr ||= {})
      end
      
      def hattr(obj)
        attr.merge!(obj)
        self
      end

      def _hattr(obj = nil)
        @hattr ||= {}
        @hattr.merge!(obj) if obj
        self
      end

      def to_html
        tag
      end

      def initialize(ident, *args)
        @ident = ident
        @procs = {}
      end
      
      def content
        ret = form.params[tag_id] || ""
        " value='%s' " % ret
      rescue
        p $!
        ""
      end

      def type_from_class
        self.class.to_s.split("::").last.downcase
      end

      def type
        " type='#{type_from_class}'"
      end

      def tag_id
        "#{@group.form.name}_#{@group.label}_#{@ident.to_s}"
      end

      def tag_ident
        " id='%s' name='%s' " % [tag_id, tag_id]
      end

      def get_attr
        if attr
          return attr.map{|v,k| " %s='%s' " % [v,k]}.join
        end
        ""
      end

      def get_hattr
        if @hattr
          return @hattr.map{|v,k| " %s='%s' " % [v,k]}.join
        end
        ""
      end

      def label
        "<label for='%s'>%s</label>" % [tag_id, @desc]
      end

      def css_cls
        "col"
      end

      def tag
        input = "<%s%s%s%s%s/>" % ["input", tag_ident, type, get_attr, content]
        "<div class='%s'%s>%s%s</div>" % [css_cls, get_hattr, label, input]
      end

      def eval_procs
        ret = ""
        (@procs || []).each_pair do |ident, proc|
          ret += proc.tag
        end
        ret
      end

      def value
        form.params[tag_id]
        
      end

      
      class FormelementWithDynamicFields < Formelement

        include MMFormElemts

        def yes
          r = yield._hattr("style" => "display:none", "data-val" => 1)
          r.form = form
          @procs[:yes] = r
        end

        def no
          r = yield._hattr("style" => "display:none", "data-val" => 0)
          r.form = form
          @procs[:no] = r
        end

        def css_cls
          str = "col"
          str << " dynamic" if @procs[:yes] or @procs[:no]
          str
        end

        def selected(k)
          if k.to_s == form.params[tag_id] then " checked=checked " else "" end
        end
      end


      class Text < FormelementWithDynamicFields
      end

      class Textarea < FormelementWithDynamicFields
        def tag
          "<div class='%s'>%s<textarea%s>%s</textarea></div>" % [css_cls, label, tag_ident, value, label, content]
        end
      end



      class Checkbox < FormelementWithDynamicFields

        def selected(k)
          if form.params[tag_id].include?(k.to_s) then " checked=checked " else "" end
        rescue
          ""
        end


        def tag
          "<div class='%s'>%s%s</div>" % [css_cls, label, content]
        end

        def content
          str = ""
          if @opts
            @opts.first.each_pair do |k, v|
              str << "<span class='form-checkbox'><input%s type='checkbox' name='%s[]' value='%s' %s/>%s</span>" % [get_attr, tag_id, k, selected(k), v]
            end
          end
          str
        end

      end

      class Radio < FormelementWithDynamicFields

       
        def tag
          "<div class='%s'%s>%s%s%s</div>" % [css_cls, get_hattr, label, content, eval_procs]
        end

        def content
          str = ""
          if @opts
            @opts.first.each_pair do |k, v|
              str << "<span class='form-radio-box %s-box'><input%s type='radio' name='%s' value='%s' %s>%s</input></span>" % [tag_id, get_attr, tag_id, k, selected(k), v]
            end
          end
          str
        end
      end

      class Select < FormelementWithDynamicFields

        def selected(k)
          if form.params[tag_id].include?(k.to_s) then " selected=selected " else "" end
        rescue
          ""
        end

        def content
          str = ""
          if @opts
            @opts.first.each_pair do |k, v|
              str << "<option value='%s' id='%s'%selected>%s</option>" % [k, tag_id, selected(k), v]
            end
          end
          str
        end

        def tag
          "<div class='%s'>%s<select%s%s>%s</select></div>" % [css_cls, label, tag_ident, get_attr, content]
        end
      end

    end

  end
end

