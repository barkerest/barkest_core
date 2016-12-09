require 'encrypted_strings'

##
# Defines a mechanism to store and retrieve configurations using the core database.
#
# The +get+ and +set+ methods allow values to be stored in an encrypted fashion as well.
#
# The encryption will use the +encrypted_config_key+ value or the +secret_key_base+ value from
# +secrets.yml+.  Ideally, use +encrypted_config_key+ to allow +secret_key_base+ to change if
# necessary.
class SystemConfig < ::BarkestCore::DbTable

  validates :key,
            presence: true,
            length: { maximum: 128 },
            uniqueness: { case_sensitive: false }

  before_save :downcase_key

  ##
  # Sets the value storing it as a YAML string.
  def value=(new_value)
    val = new_value.nil? ? nil : new_value.to_yaml
    write_attribute :value, val
  end

  ##
  # Gets the value loading it from a YAML string.
  def value
    val = read_attribute(:value).to_s
    return nil if val.empty?
    YAML.load val
  end

  ##
  # Gets a value from the database.
  #
  # If the value was stored encrypted, it will be decrypted before being returned.
  #
  # As a feature during testing +config/key_name.yml+ will be used if it exists and the database
  # value is missing.
  #
  def self.get(key_name)
    begin
      record = where(key: key_name.to_s.downcase).first

      if record
        value = record.value
        if value.is_a?(Hash) && value.keys.include?(:encrypted_value)
          value = value[:encrypted_value]
          unless value.nil? || value == ''
            value = YAML.load(crypto_cipher.decrypt(value)) rescue nil
          end
        end
      elsif Rails.env.test?
        yml_file = "#{BarkestCore.app_root}/config/#{key_name}.yml"
        value = File.exist?(yml_file) ? YAML.load_file(yml_file) : nil
      else
        value = nil
      end

      value
    rescue
      nil # if 'system_configs' table has not been created, return nil.
    end
  end

  ##
  # Stores a value to the database.
  #
  # All values are converted into YAML strings before storage.
  #
  # If +encrypt+ is set to true, then the value will be encrypted before being stored.
  def self.set(key_name, value, encrypt = false)
    key_name = key_name.to_s.downcase
    if encrypt
      value = crypto_cipher.encrypt(value.to_yaml) unless value.nil? || value == ''
      value = { encrypted_value: value }
    end
    record = find_or_initialize_by(key: key_name)
    record.value = value
    record.save
  end

  private

  def self.crypto_password
    @crypto_password ||= Rails.application.secrets[:encrypted_config_key] || Rails.application.secrets[:secret_key_base]
  end

  def self.crypto_cipher
    @crypto_cipher ||= EncryptedStrings::SymmetricCipher.new(password: crypto_password)
  end

  def downcase_key
    key.downcase!
  end

end
