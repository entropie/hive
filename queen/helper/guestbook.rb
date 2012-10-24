# -*- coding: utf-8 -*-
#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module Hive
  module Helper

    module GuestBook

      def can_post?
        not (session[:plugin_gb_entry_at] and (Time.now - session[:plugin_gb_entry_at]) < PluginGuestbookController::GUESTBOOK_CREATE_DELAY)
      end

      private :can_post?

      SALT = "48939843258495iflkdvf4oguh39ß50843085438905u430fjkr"

      class Entry < Struct.new(:name, :email, :eid, :text, :date)
        def to_html(r)
          r.send(:plugin_render_file, PluginGuestbookController, "guestbook/_entry.haml", :entry => self)
        end
      end

      class GuestBookException < Exception; end
      class EntryAlreadyExist < GuestBookException; end
      class MissingInput < GuestBookException; end

      class Entries < Array

        attr_reader :guestbook, :file

        def initialize(guestbook, file = "#{Time.now.year}.yaml")
          @guestbook = guestbook
          @file = File.join(guestbook.path, file)
        end

        def read!
          if File.exist?(file)
            YAML::load_file(file).sort_by{ |e| e.date }.reverse.each{ |e| self << e}
          else
            self
          end
        end

        def write(what = self)
          contents = YAML::dump(what)
          puts "writing #{contents.size}B to #{file}"
          File.open(file, 'w+'){ |fp| fp.write(contents) }
        end

        def push(entry)
          unless any?{ |e| e.eid == entry.eid }
            super(entry)
            write
          else
            raise EntryAlreadyExist, "already exist"
          end
          self
        end

        def find(eid)
          select{ |e| e.eid == eid }.first
        end

      end

      class GuestBook
        attr_reader :beehive

        def initialize(beehive)
          @beehive = beehive
        end

        def entries(start = nil, limit = nil)
          unless @entries
            @entries = Entries.new(self)
            @entries.read!
          end

          return @entries[start.to_i..-1] if start
          return @entries.first(limit.to_i) if limit
          @entries
        end

        def find(eid)
          entries.find(eid)
        end

        def create(name, email, text)
          eid = Digest::SHA1.hexdigest("#{name}#{email}#{text}#{SALT}")
          entry = Entry.new(name, email, eid, text, Time.now)
          entries.push(entry)
          entry
        end

        def path
          @path ||= @beehive.media_path("guestbook")
        end
      end
    end
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
