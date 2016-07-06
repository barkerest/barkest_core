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

end