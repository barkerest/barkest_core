BarkestCore::InstallGenerator.class_eval do
  ##
  # Generates an email.yml configuration file.
  def configure_email
    config_file = 'config/email.yml'

    attributes = [
        ['config_mode', :ask_for_string, %w(smtp test none)],
        ['default_sender', :ask_for_string, ->(val){BarkestCore::EmailTester.valid_email?(val)}],
        ['default_recipient', :ask_for_string, ->(val){BarkestCore::EmailTester.valid_email?(val)}],
        ['default_hostname', :ask_for_string],
        { 'smtp' =>
              [
                  ['address', :ask_for_string, nil, 'smtp_server'],
                  ['port', :ask_for_int, (0..65535), 'smtp_port'],
                  ['authentication', :ask_for_string, %w(plain login cram_md5), 'smtp_authentication'],
                  ['ssl', :ask_for_bool, nil, 'use_ssl_for_smtp'],
                  ['enable_starttls_auto', :ask_for_bool, nil, 'use_starttls_for_smtp'],
                  ['user_name', :ask_for_string, nil, 'smtp_username'],
                  ['password', :ask_for_secret, nil, 'smtp_password']
              ]
        }
    ]

    default = {
        'config_mode' => 'test',
        'default_sender' => 'support@barkerest.com',
        'default_recipient' => 'support@barkerest.com',
        'default_hostname' => 'localhost:3000'
    }

    configure_the 'email connection', config_file, attributes, 'config_mode', default
  end

  def test_email
    config_file = 'config/email.yml'

    config_data = YAML.load_file(config_file).symbolize_keys

    [ :test, :development, :production ].each do |section|
      cfg = (config_data[section] || {}).symbolize_keys
      if cfg[:config_mode].to_s.downcase == 'smtp'
        tell "> Testing #{section} email config..."
        begin
          smtp = Net::SMTP.new(cfg[:address], cfg[:port])
          begin
            smtp.enable_ssl if cfg[:ssl]
            smtp.start(cfg[:default_hostname], cfg[:user_name], cfg[:password], cfg[:authentication].to_sym)
            smtp.send_message(<<-MESSAGE, cfg[:default_sender], cfg[:default_recipient])
From: #{cfg[:default_sender]}
To: #{cfg[:default_recipient]}
Subject: Test message

This is a test message sent with the #{section} configuration for #{cfg[:default_hostname]}.
            MESSAGE
          ensure
            smtp.finish rescue nil
          end
          tell '  Successfully sent test message.', :green
        rescue =>e
          tell "  Failed to send test message: #{e.inspect}", :red
        end

      end
    end
  end

end