require 'jquery-rails'
require 'bootstrap-sass'
require 'prawn-rails'
require 'ntlm/smtp'
require 'exception_notification'

module BarkestCore
  class Engine < ::Rails::Engine


    # Ensure the default logo gets compiled.
    config.assets.precompile += %w( barkest_core/barcode-B.svg )

    ##
    # Initialize the library.
    initializer 'barkest_core.initialize' do |app|

      # cache the application root path.
      BarkestCore.app_root = app.root

      app.paths['app/helpers'] << 'app/helpers/barkest_core'

      # get the email config.
      cfg = BarkestCore.email_config
      mode = cfg[:config_mode].to_s.downcase
      [ config.action_mailer, ActionMailer::Base ].each do |obj|
        # configure action_mailer accordingly.
        if %w(smtp test).include?(mode) && !cfg[:default_hostname].blank?
          obj.default_url_options = { host: cfg[:default_hostname] }
        end
        if mode == 'smtp'
          obj.raise_delivery_errors = true
          obj.perform_deliveries = true
          obj.delivery_method = :smtp
          obj.smtp_settings = cfg  # remove the non-smtp settings.
                                                   .except(
                                                       :config_mode,
                                                       :default_recipient,
                                                       :default_sender,
                                                       :default_hostname
                                                   )
        else
          obj.delivery_method = mode.to_sym
        end

        # in production mode, we want exceptions sent to the default recipient.
        if Rails.env.production?
          Rails.application.config.middleware.use(
              ExceptionNotification::Rack,
              email: {
                  email_prefix: "[BarkerEST #{Rails.application.app_name} (#{Rails.application.app_version})] ",
                  sender_address: cfg[:default_sender],
                  exception_recipients: [ cfg[:default_recipient] ]
              }
          )
        end
      end


      # configure prawn-rails
      PrawnRails.config do |config|
        config.page_layout = :portrait
        config.page_size = 'LETTER'
      end


    end

  end
end
