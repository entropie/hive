require 'net/http'

module ReCaptcha
    
  VERIFY = 'https://www.google.com/recaptcha/api/siteverify'
    
  class << self
    attr_accessor :public_key, :private_key, :server
    attr_reader   :verify
  end

  def self.recaptcha_tag
    '<div class="g-recaptcha" data-sitekey="%s"></div>' % Queen::BEEHIVE.config.recaptcha[:public]    
  end


  def private_key
    beehive.config.recaptcha[:secret]
  end

  def recaptcha_correct?
    recaptcha = Net::HTTP.post_form URI.parse(VERIFY), {
                                      :secret => private_key,
                                      :response   => request[:"g-recaptcha-response"]
                                    }
    answer = JSON.parse(recaptcha.body)
    answer["success"]
  rescue
    false
  end
    
end
