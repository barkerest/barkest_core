require 'jquery-rails'
require 'bootstrap-sass'
require 'ntlm/smtp'
require 'exception_notification'

module BarkestCore
  class Engine < ::Rails::Engine

    # Ensure the default logo gets compiled.
    config.assets.precompile += %w( barkest_core/barcode-B.svg
barkest_core/ArchivoNarrow-Bold.ttf
barkest_core/ArchivoNarrow-BoldItalic.ttf
barkest_core/ArchivoNarrow-Italic.ttf
barkest_core/ArchivoNarrow-Regular.ttf  )


    ##
    # Update the databases as needed.
    Rails::Application::Finisher.initializer 'barkest_core.finisher' do |app|
      MsSqlDbDefinition.registered.each do |name,updater|
        config = BarkestCore.db_config(name)
        if config[:database] && config[:host]
          Rails.logger.debug "Beginning updates for #{name} DB."
          begin
            updater.update_db config
          rescue BarkestCore::MsSqlDbDefinition::NeedFullAccess => e
            Rails.logger.error "The configuration for #{name} DB is missing a valid update user."
          rescue StandardError => e
            Rails.logger.error "The updater for #{name} DB was unable to complete.\n#{e}"
          end
        else
          Rails.logger.warn "Skipping updates for #{name} DB since :database and/or :host is not set."
        end
      end
    end


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

      ActionView::Template.register_template_handler :csvrb, BarkestCore::CsvHandler::Handler


      # add date formats for American formatted dates.
      Time::DATE_FORMATS[:date] = '%m/%d/%y'
      Time::DATE_FORMATS[:date4] = '%m/%d/%Y'
      Date::DATE_FORMATS[:date] = '%m/%d/%y'
      Date::DATE_FORMATS[:date4] = '%m/%d/%Y'

      require_relative '../../app/controllers/barkest_core/application_controller_base'

    end

  end
end
