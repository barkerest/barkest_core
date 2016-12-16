require 'barkest_core/engine'
require 'fileutils'
require 'time'

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
  # This will either be an explicit +barkest_core+ section or a normal environment section (ie - +production+).
  # However other databases can be defined via the SystemConfig model.
  #
  # The +database.yml+ file is checked first, followed by SystemConfig.
  # If neither of those defines the specific database, then we fall back on +database.yml+ to load
  # the global configuration for the environment.
  #
  # For instance, if you want the configuration for :mydb in the :development environment:
  # * Check in +database.yml+ for "mydb_development".
  # * Check in +database.yml+ for "mydb".
  # * Check in SystemConfig for "mydb" (unless "mydb" == "barkest_core").
  # * Check in +database.yml+ for "development".
  # * Fall back on default connection used by ActiveRecord::Base.
  #
  # Returned hash will have symbol keys.
  def self.db_config(other = nil, env = nil)
    if other
      @db_configs ||= {}

      other = other.to_sym
      env = (env || Rails.env).to_sym
      key = :"#{other}_#{env}"

      @db_configs[key] ||=
        begin
          avail = avail_db_configs

          # for any db connection other than the core connection, check
          # in the system config table as well.
          syscfg = (other == :barkest_core) ? nil : SystemConfig.get(other)
          defcfg = (other == :barkest_core) ? avail[env] : db_config_defaults(other)

          # Preference
          (
          avail[key] ||                         # 1: barkest_core_development
              avail[other] ||                       # 2: barkest_core
              syscfg ||                             # 3: SystemConfig: barkest_core
              defcfg ||                             # 4: YAML[env] or defaults depending on db name
              ActiveRecord::Base.connection_config  # 5: default connection (hopefully never gets used)
          ).merge(defcfg.select do |k,_|
            [ # reset name, type, and label for extra values.
                :extra_1_name, :extra_1_type, :extra_1_label,
                :extra_2_name, :extra_2_type, :extra_2_label,
                :extra_3_name, :extra_3_type, :extra_3_label,
                :extra_4_name, :extra_4_type, :extra_4_label,
                :extra_5_name, :extra_5_type, :extra_5_label
            ].include?(k)
          end)
        end

      @db_configs[key] = @db_configs[key].symbolize_keys
    elsif env
      db_config(:barkest_core, env)
    else
      @db_config ||= db_config(:barkest_core, Rails.env)
    end
  end

  ##
  # Determines if the configuration for the specified database is stored in the global configuration file.
  def self.db_config_is_file_based?(db_name)
    avail = avail_db_configs.keys
    avail.include?(:"#{db_name}_#{Rails.env}") || avail.include?(:"#{db_name}")
  end

  ##
  # Sets the defaults for a database configuration.
  def self.register_db_config_defaults(db_name, defaults)
    # reset the config cache.
    @db_configs = nil

    db_name = db_name.to_s
    return false if db_name.blank?
    return false if db_name == 'barkest_core'

    # set the defaults.
    @db_config_defaults ||= {}
    @db_config_defaults[db_name.to_sym] = defaults

    true
  end

  ##
  # Gets the email configuration for the application.
  #
  # Email settings are stored under the :email key within SystemConfig.
  #
  # Returned keys will be symbols.
  def self.email_config
    @email_config ||= email_config_defaults(nil).merge( (SystemConfig.get(:email) || {}).symbolize_keys )
  end

  ##
  # Provides the defaults to be returned by email_config when settings are missing.
  def self.email_config_defaults(new_defaults = {})
    @email_config_defaults = nil if new_defaults
    @email_config_defaults ||=
        {
            config_mode: :none,
            default_sender: 'support@barkerest.com',
            default_recipient: 'support@barkerest.com',
            default_hostname: 'localhost',
        }.merge((new_defaults || {}).symbolize_keys)
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
  # Auth settings are stored under the :auth key within SystemConfig.
  #
  # Returned keys will be symbols.
  def self.auth_config
    @auth_config ||=
        begin
          cfg = auth_config_defaults(nil).symbolize_keys.merge( (SystemConfig.get(:auth) || {}).symbolize_keys )

          cfg[:enable_db_auth] = true unless cfg[:enable_ldap_auth]

          cfg
        end
  end

  ##
  # Provides the defaults to be provided by auth_config when settings are missing.
  def self.auth_config_defaults(new_defaults = {})
    @auth_config_defaults = nil if new_defaults
    @auth_config_defaults ||=
        {
            enable_db_auth: true,
            enable_ldap_auth: false,
        }.merge((new_defaults || {}).symbolize_keys)
  end

  # :nodoc:
  def self.config
    BarkestCore::Engine.config
  end

  ##
  # Tells the hosting service (Passenger) that we want to restart the application.
  def self.request_restart
    FileUtils.touch restart_file
  end

  ##
  # Determines if the application is still waiting on a restart to take place.
  def self.restart_pending?
    return false unless File.exist?(restart_file)

    request_time = File.mtime(restart_file)

    request_time > start_time
  end

  ##
  # Gets a list of key gems with their versions.
  #
  # This is useful for informational displays such as brief application version diplays.
  #
  # Supply one or more patterns for gem names.  If you supply none, then the default
  # pattern list is used.
  def self.gem_list(*patterns)
    ret = []

    if patterns.blank?
      patterns = key_gem_patterns
    elsif patterns.first.is_a?(TrueClass)
      patterns = key_gem_patterns + patterns[1..-1]
    elsif patterns.last.is_a?(TrueClass)
      patterns = patterns[0...-1] + key_gem_patterns
    end

    patterns = patterns.flatten.inject([]) { |memo,v| memo << v unless memo.include?(v); memo }

    Gem::Specification.to_a.sort{|a,b| a.name <=> b.name}.each do |gem|
      patterns.each do |pat|
        if pat.is_a?(String) && gem.name == pat
          ret << [ gem.name, gem.version.to_s ]
        elsif pat.is_a?(Regexp) && pat.match(gem.name)
          ret << [ gem.name, gem.version.to_s ]
        end
      end
    end

    ret
  end

  ##
  # Adds a key gem pattern to the default gem_list results.
  def self.add_key_gem_pattern(pattern)
    pattern = pattern.to_s.downcase
    unless pattern.blank?
      key_gem_patterns << pattern unless key_gem_patterns.include?(pattern)
    end
    key_gem_patterns.include? pattern
  end

  private

  def self.key_gem_patterns
    @key_gem_patterns ||= [ 'rails', /^barkest/ ]
  end

  def self.db_config_defaults(db_name)
    @db_config_defaults ||= {}
    @db_config_defaults[db_name.to_sym] || {}
  end

  def self.avail_db_configs
    @avail_db_configs ||=
        begin
          db_yml = "#{self.app_root}/config/database.yml"
          if File.exist?(db_yml)
            YAML.load_file(db_yml).symbolize_keys
          else
            ActiveRecord::Base.configurations.to_h.symbolize_keys
          end
        end
  end

  def self.restart_file
    @restart_file ||= "#{self.app_root}/tmp/restart.txt"
  end

  def self.start_time
    @start_time ||= Time.now
  end

  # make sure @start_time gets set...
  start_time

end

# Preload the concerns and process the extensions.
Dir.glob(File.expand_path('../barkest_core/{concerns,extensions,handlers}/*.rb', __FILE__)).each do |lib_code|
  require lib_code
end
