BarkestCore::InstallGenerator.class_eval do
  ##
  # Generates a secrets.yml configuration file.
  def configure_secrets
    config_file = 'config/secrets.yml'

    attributes = [
        [ 'recaptcha_public_key', :ask_for_string ],
        [ 'recaptcha_private_key', :ask_for_string ],
        [ 'secret_key_base',  :ask_for_secret_key_base ]
    ]

    default = {}

    configure_the 'recaptcha service', config_file, attributes, nil, default
  end

  private

  def ask_for_secret_key_base(question, default = '')
    puts "Current secret key base: #{default[0...20]}..." unless options.quiet?
    say 'Changing the secret key base will invalidate encrypted values.', :yellow
    return default unless ask_for_bool('Do you want to change the secret key base to a new random value?', false)
    SecureRandom.urlsafe_base64(72)
  end
end