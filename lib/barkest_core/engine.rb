require 'jquery-rails'
require 'bootstrap-sass'
require 'prawn-rails'
require 'ntlm/smtp'

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
      end




      # configure prawn-rails
      PrawnRails.config do |config|
        config.page_layout = :portrait
        config.page_size = 'LETTER'
      end


    end

  end
end
