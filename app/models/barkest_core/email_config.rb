module BarkestCore
  class EmailConfig
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :config_mode, :default_sender, :default_recipient, :default_hostname
    attr_accessor :address, :port, :authentication, :ssl, :enable_starttls_auto, :user_name, :password

    VALID_CONFIG_MODES = %w(none smtp test)
    VALID_AUTH_MODES = %w(none plain login cram_md5 ntlm)

    validates :config_mode, inclusion: { in: VALID_CONFIG_MODES }
    validates :default_sender, presence: true
    validates :default_recipient, presence: true
    validates :default_hostname, presence: true

    with_options if: :smtp?, presence: true do
      validates :address
      validates :port
      validates :authentication, inclusion: { in: VALID_AUTH_MODES }
    end

    validate :smtp_validate, if: :smtp?

    def initialize(*args)
      args.each do |arg|
        if arg.is_a?(Hash)
          arg.each do |k,v|
            if respond_to?(:"#{k}?")
              send :"#{k}=", ((v === true || v === '1') ? '1' : '0')
            elsif respond_to?(k)
              send :"#{k}=", v.to_s
            end
          end
        end
      end
    end

    def smtp?
      config_mode.to_s.downcase == 'smtp'
    end

    def ssl?
      ssl.to_s.to_i != 0
    end

    def enable_starttls_auto?
      enable_starttls_auto.to_s.to_i != 0
    end

    def smtp_validate
      # no need to test unless we are configured for SMTP.
      return nil unless smtp?

      # already failed if these are missing.
      return nil if address.blank? || port.blank? || authentication.blank?

      # or these
      return nil if default_sender.blank? || default_recipient.blank? || default_hostname.blank?

      # send a test message.
      begin
        client = Net::SMTP.new(address, port)
        begin
          client.enable_ssl if ssl?
          client.start(default_hostname, user_name, password, authentication.to_sym)
          msgstr = <<-MESSAGE
From: #{default_sender}
To: #{default_recipient}
Subject: Test message

This is a test message sent with the new #{Rails.env} configuration for #{default_hostname}.
This message was sent at #{Time.zone.now}.
          MESSAGE
          client.send_message(msgstr, default_sender, default_recipient)
        ensure
          client.finish rescue nil
        end

        nil
      rescue =>e
        errors.add :base, "Failed to send test message. " + e.message
      end
    end

    def to_h
      {
          config_mode: config_mode.to_s.to_sym,
          default_sender: default_sender.to_s,
          default_recipient: default_recipient.to_s,
          default_hostname: default_hostname.to_s,
          address: address.to_s,
          port: port.to_s.to_i,
          authentication: authentication.to_s.to_sym,
          ssl: ssl?,
          enable_starttls_auto: enable_starttls_auto?,
          user_name: user_name.to_s,
          password: password.to_s,
      }
    end

    def save
      SystemConfig.set :email, to_h, true
    end

    def EmailConfig.load
      EmailConfig.new SystemConfig.get(:email)
    end


  end
end
