#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

class PluginGuestbookController < QueenController

  GUESTBOOK_CREATE_DELAY = 60*60

  map "/p/guestbook"

  def guestbook
    Helper::GuestBook::GuestBook.new(beehive)
  end
  private :guestbook

  def create
    name, email, text = request[:name], request[:email], request[:text]
    errors = []

    [:name, :email, :text].each do |field|
      if request[field].nil? or request[field].empty?
        errors << [field]
      end
    end

    unless errors.empty?
      return { :ok => false, :errors => errors }
    end

    # ok
    entry = guestbook.create(name, email, text)

    session[:plugin_gb_entry_at] = Time.now

    { :ok => true, :url => PluginGuestbookController.r(:_entry, entry.eid ) }
  rescue Helper::GuestBook::EntryAlreadyExist
    { :ok => false }
  end

  def _entry(eid)
    @entry = guestbook.find(eid)
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
