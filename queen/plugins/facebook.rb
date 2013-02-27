#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

module FaceBook

  FACEBOOK_DEFAULT_PROFILE_PIC_SHA = "a36c79a464fe82b8ea6a77cecce9546e31b4f4e5"
  
  include Koala

  def self.app_config
    Hive::Queen::BEEHIVE.config.facebook
  end

  def self.mode
    Hive::Queen::BEEHIVE.mode
  end

  def self.fbsecret
    if app_config and not FaceBook.const_defined?("SECRET")
      FaceBook.const_set("SECRET", app_config[mode][:secret])
    end
    SECRET
  end

  def self.fbid
    if app_config and not FaceBook.const_defined?("ID")
      FaceBook.const_set("ID", app_config[mode][:id])
    end
    ID
  end

  def self.callback_url
    app_config[mode][:callback_url]
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
