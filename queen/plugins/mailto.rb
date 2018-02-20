module HiveMailer
  
  Mail.defaults do
    #delivery_method :logger
    delivery_method :smtp, {
                      :address              => "smtp.gmail.com",
                      :port                 => 587,
                      :authentication       => 'plain',
                      :user_name            => 'mictro@gmail.com',
                      :domain               => 'schwierige-felle.de',
                      :password             => begin File.readlines( File.expand_path('~/.gmailpw') ).join rescue "" end,
                      :enable_starttls_auto => true  }

  end
  
  def Mailer(ident, content, html_content)
    #template = File.readlines( beehive.view_path("mail/#{ident}.haml") ).join

    m = Mail.new do
      to         "michael@schwierige-felle.de"
      from       "noreply@wecoso.de"

      subject    "subject"

      text_part do
        body content
      end

      html_part do
        content_type('text/html; charset=UTF-8')
        body html_content
      end
      
    end
    m
  end


end

