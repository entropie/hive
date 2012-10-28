#
#
# Author:  Michael 'entropie' Trommer <mictro@gmail.com>
#

require "openssl"
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_PEER)

module Hive
  module Helper
    module Mail

      class GmailSender
        SMTP_ADDR = 'smtp.gmail.com'
        def initialize(opts = {})
          unless opts[:login] && opts[:password]
            raise ArgumentError.new("provide a login and password")
          end
          @login    = opts[:login]
          @password = opts[:password]
          @domain   = @login[/@(.+)$/,1]
        end

        def deliver(opts = {})
          @recipients = opts[:to]
          @subject = opts[:subject]
          @body = opts[:body]
          @from = opts[:reply_to]
          smtp_args = [SMTP_ADDR, 25, @domain, @login, @password, :login]
          Net::SMTP.start(*smtp_args) do |smtp|
            status = smtp.send_message message, @login, @recipients
          end
        end

        private

        def message
          <<-EOS
FROM: #{@login}
TO: #{@recipients.is_a?(Array) ? @recipients.join(', ') : @recipients}
SUBJECT: #{@subject}

#{@body}
EOS
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
