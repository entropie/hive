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

    attr_accessor :action

    def initialize(name)
      @name = name
      @groups = Formgroups.new(self)
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
    
    def to_html
      "<form%s name='%s' id='%s'>%s%s</form>" % [action, @name.to_s, @name.to_s, @groups.to_html, submit]
    end


    class Formgroups < Array
      def initialize(form)
        @form = form
      end

      def to_html
        map{|g|  g.to_html }.join
      end
    end

    class Formgroup

      attr_accessor :form
      
      def method_missing(m, *rest, &blk)
        fe = Formelement.decide(m, *rest)
        fe.group = self
        if block_given?
          fe.instance_eval(&blk)
        end
        @elements << fe
        fe
      end

      def initialize(label, desc)
        @label, @desc = label, desc
        @elements = []
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
      def self.decide(m, *args)
        clz = case m.to_s
              when /^xo_(.*)$/
                Radio.new($1)
              when /^xx_(.*)$/
                Checkbox.new($1)
              when /^XO_(.*)$/
                Select.new($1)
              when /^text_(.*)$/
                Textarea.new($1)
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

      def values(vals)
        @values = vals
      end
      
      def to_html
        tag
      end
      
      def opts=(obj)
        @opts = obj
      end

      def desc=(str)
        @desc = str
      end

      def group=(grp)
        @group = grp
      end

      def initialize(ident, *args)
        @ident = ident
      end
      
      def content
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

      def get_values
        if @values
          return @values.map{|v,k| " %s='%s'" % [v,k]}.join
        end
        ""
      end

      def label
        "<label for='%s'>%s</label>" % [tag_id, @desc]
      end

      def tag
        "<div class='col'>%s<%s%s%s%s%s/></div>" % [label, self.class::TAG, tag_ident, type, get_values, content]
      end
      
      class Text < Formelement
        TAG = "input"
      end

      class Textarea < Formelement
        def tag
          "<div class='col'>%s<textarea%s></textarea></div>" % [label, tag_ident, label, content]
        end
      end

      class Checkbox < Formelement
        def tag
          "<div class='col'>%s%s</div>" % [label, content]
        end

        def content
          str = ""
          if @opts
            @opts.first.each_pair do |k, v|
              str << "<input type='checkbox' name='%s[]' value='%s' />%s" % [tag_id, k, v, v]
            end
          end
          str
        end

      end

      class Radio < Formelement
        TAG = "input"

        def tag
          "<div class='col'>%s%s</div>" % [label, content]
        end

        def content
          str = ""
          if @opts
            @opts.first.each_pair do |k, v|
              str << "<span class='%s-box'><input type='radio' name='%s' value='%s'>%s</input></span>" % [tag_id, tag_id, k, v, v]
            end
          end
          str
        end

      end

      class Select < Formelement
        TAG = "select"

        def content
          str = ""
          if @opts
            @opts.first.each_pair do |k, v|
              str << "<option value='%s' id='%s'>%s</option>" % [k, tag_id, v]
            end
          end
          str
        end

        def tag
          "<div class='col'>%s<select%s%s>%s</select></div>" % [label, tag_ident, get_values, content]
        end
      end

      class Textarea < Formelement
        TAG = "textarea"
      end
    end

  end
end

