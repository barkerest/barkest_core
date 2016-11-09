require 'barkest_core/engine'

module BarkestCore

  ##
  # Cache of the application root path for use within the engine.
  mattr_accessor :app_root

  ##
  # Determines the accessibility of /users (index) and /users/1 (show) actions.
  #
  # Set to true to deny access to the users' list and user profiles for non-admin users.
  # Set to false to allow access to the users' list for all logged-in users.
  mattr_accessor :lock_down_users

  ##
  # Gets the database configuration for the auth models.
  #
  # The +barkest_core+ database must be defined in +database.yml+.
  # However other databases can be defined via the SystemConfig model.
  #
  # The +database.yml+ file is checked first, followed by SystemConfig.
  # If neither of those defines the specific database, then we fall back on +database.yml+ to load
  # the global configuration for the environment.
  #
  # For instance, if you want the configuration for :mydb in the :development environment:
  # * Check in +database.yml+ for "mydb_development".
  # * Check in +database.yml+ for "mydb".
  # * Check in SystemConfig for "mydb_development".
  # * Check in SystemConfig for "mydb".
  # * Check in +database.yml+ for "development".
  # * Fall back on default connection used by ActiveRecord::Base.
  #
  # Returned hash will have symbol keys.
  def self.db_config(other = nil, env = nil)
    if other
      env = (env || Rails.env).to_sym

      cfg =
        begin
          db_yml = "#{self.app_root}/config/database.yml"
          avail =
              if File.exist?(db_yml)
                YAML.load_file(db_yml).symbolize_keys
              else
                ActiveRecord::Base.configurations.to_h.symbolize_keys
              end

          # for any db connection other than the core connection, check
          # in the system config table as well.
          syscfg = (other == :barkest_core) ? nil : SystemConfig.get(other)

          # Preference
          avail[:"#{other}_#{env}"] ||          # 1: barkest_core_development
          avail[other.to_sym] ||                # 2: barkest_core
          syscfg ||                             # 3: SystemConfig: barkest_core
          avail[env] ||                         # 4: development
          ActiveRecord::Base.connection_config  # 5: default connection
        end

      (cfg || db_config_defaults(other)).symbolize_keys
    elsif env
      db_config(:barkest_core, env)
    else
      @db_config ||= db_config(:barkest_core, Rails.env)
    end
  end

  ##
  # Provides the defaults to be returned by db_config when settings are missing.
  #
  # Can be overridden by child projects to provide appropriate defaults.
  def self.db_config_defaults(db_name)
    { }
  end

  ##
  # Gets the email configuration for the application.
  #
  # Define these settings in your +config/email.yml+ file.
  #
  # Or define them using the :email key with SystemConfig.
  #
  # Keys will be symbols.
  def self.email_config
    @email_config ||=
        begin
          email_yml = "#{self.app_root}/config/email.yml"

          cfg = SystemConfig.get(:email)

          unless cfg
            if File.exist?(email_yml)
              cfg = YAML.load_file(email_yml)[Rails.env]
            end
          end

          email_config_defaults.symbolize_keys.merge( (cfg || {}).symbolize_keys )
        end
  end

  ##
  # Provides the defaults to be returned by email_config when settings are missing.
  #
  # Can be overriden by child projects to provide appropriate defaults.
  def self.email_config_defaults
    {
        config_mode: :none,
        default_sender: 'support@barkerest.com',
        default_recipient: 'support@barkerest.com',
        default_hostname: 'localhost',
    }
  end

  ##
  # Gets the authorization configuration.
  #
  # Basically this does two things.
  # 1) It will enable/disable internal database authentication.
  # 2) It will enable/disable ldap authentication.
  #
  # If ldap authentication is not configured then internal database authentication
  # is forcibly enabled.  Both modes can be active simultaneously.
  #
  def self.auth_config
    @auth_config ||=
        begin
          auth_yml = "#{self.app_root}/config/auth.yml"

          cfg = SystemConfig.get(:auth)

          unless cfg
            if File.exist?(auth_yml)
              cfg = YAML.load_file(auth_yml)[Rails.env]
            end
          end


          cfg = auth_config_defaults.symbolize_keys.merge( (cfg || {}).symbolize_keys )

          cfg[:enable_db_auth] = true unless cfg[:enable_ldap_auth]

          cfg
        end
  end

  ##
  # Provides the defaults to be provided by auth_config when settings are missing.
  #
  # Can be overriden by child projects to provide appropriate defaults.
  def self.auth_config_defaults
    {
        enable_db_auth: true,
        enable_ldap_auth: false,
    }
  end

  # :nodoc:
  def self.config
    BarkestCore::Engine.config
  end

end

# Preload the concerns and process the extensions.
Dir.glob(File.expand_path('../barkest_core/{concerns,extensions}/*.rb', __FILE__)).each do |lib_code|
  require lib_code
end
