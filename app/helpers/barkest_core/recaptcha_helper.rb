module BarkestCore
  ##
  # This module makes it easy to work with Google's recaptcha service.
  #
  # Simply add +recaptcha_public_key+ and +recaptch_private_key+ to your
  # +secrets.yml+ configuration file, or provide +RECAPTCHA_PUBLIC_KEY+
  # and +RECAPTCHA_PRIVATE_KEY+ environment variables.
  module RecaptchaHelper

    private

    def load_recaptcha_keys
      tmp = ENV['RECAPTCHA_PUBLIC_KEY'].to_s
      @recaptcha_site_key = tmp.blank? ? Rails.application.secrets[:recaptcha_public_key].to_s : tmp
      tmp = ENV['RECAPTCHA_PRIVATE_KEY'].to_s
      @recaptcha_secret_key = tmp.blank? ? Rails.application.secrets[:recaptcha_private_key].to_s : tmp
    end

    def recaptcha_site_key
      load_recaptcha_keys unless @recaptcha_site_key
      @recaptcha_site_key
    end

    def recaptcha_secret_key
      load_recaptcha_keys unless @recaptcha_secret_key
      @recaptcha_secret_key
    end

    def recaptcha_disabled?
      Rails.env.test? || recaptcha_site_key.blank? || recaptcha_secret_key.blank?
    end

    public

    ##
    # Adds the recaptcha challenge to a form.
    #
    # This will include the recaptcha API from Google automatically and inserts a +<br>+ sequence after the challenge
    # if +include_break+ is set to true (the default).
    def add_recaptcha_challenge(include_break = true)
      unless recaptcha_disabled?
        "<div class=\"g-recaptcha\" data-sitekey=\"#{h recaptcha_site_key}\"></div>\n<script src=\"https://www.google.com/recaptcha/api.js\"></script>#{include_break ? '<br>' : ''}".html_safe
      end
    end

    ##
    # Verifies the response from a recaptcha challenge in a controller.
    #
    # It will return true if the recaptcha challenge passed.  It always returns true in the 'test' environment.
    #
    # If a +model+ is provided, then an error will be added to the model if the challenge fails.
    # Because this is handled outside of the model (since it's based on the request and not the model),
    # you should first check if the model is valid and then verify the recaptcha challenge to ensure you
    # don't lose the recaptcha error message.
    #
    #   if model.valid? && verify_recaptcha_challenge(model)
    #     model.save
    #     redirect_to :show, id: model
    #   else
    #     render 'edit'
    #   end
    #
    def verify_recaptcha_challenge(model = nil)

      # always true in tests.
      return true if recaptcha_disabled?

      # model must respond to the 'errors' message and the result of that must respond to 'add'
      if !model || !model.respond_to?('errors') || !model.send('errors').respond_to?('add')
        model = nil
      end

      begin
        recaptcha = nil

        http = Net::HTTP

        remote_ip = (request.respond_to?('remote_ip') && request.send('remote_ip')) || (env && env['REMOTE_ADDR'])
        verify_hash = {
            secret: recaptcha_secret_key,
            remoteip: remote_ip,
            response: params['g-recaptcha-response']
        }

        Timeout::timeout(5) do
          uri = URI.parse('https://www.google.com/recaptcha/api/siteverify')
          http_instance = http.new(uri.host, uri.port)
          if uri.port == 443
            http_instance.use_ssl = true
            http_instance.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(verify_hash)
          recaptcha = http_instance.request(request)
        end
        answer = JSON.parse(recaptcha.body)

        if answer['success'].to_s.downcase == 'true'
          return true
        else
          if model
            model.errors.add(:base, 'Recaptcha verification failed.')
          end
          return false
        end

      rescue Timeout::Error
        if model
          model.errors.add(:base, 'Recaptcha unreachable.')
        end
      end
    end

  end
end
