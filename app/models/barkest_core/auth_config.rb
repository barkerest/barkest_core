module BarkestCore

  ##
  # Defines the authentication configuration for the system.
  class AuthConfig
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :enable_db_auth, :enable_ldap_auth, :ldap_host, :ldap_port, :ldap_base_dn, :ldap_ssl,
                  :ldap_browse_user, :ldap_browse_password, :ldap_auto_activate, :ldap_system_admin_groups

    validate do
      errors.add :enable_db_auth, 'must be selected if enable_ldap_auth is not selected' unless enable_ldap_auth? || enable_db_auth?
    end

    with_options if: :enable_ldap_auth?, presence: true do |cfg|
      cfg.validates :ldap_host
      cfg.validates :ldap_port
      cfg.validates :ldap_base_dn
      cfg.validates :ldap_browse_user
      cfg.validates :ldap_browse_password
      cfg.validates :ldap_system_admin_groups
    end

    ##
    # Creates the configuration.
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

    ##
    # Is DB authentication enabled?
    def enable_db_auth?
      enable_db_auth.to_s.to_i != 0
    end

    ##
    # Is LDAP authentication enabled?
    def enable_ldap_auth?
      enable_ldap_auth.to_s.to_i != 0
    end

    ##
    # Is SSL enabled for LDAP authentication?
    def ldap_ssl?
      ldap_ssl.to_s.to_i != 0
    end

    ##
    # Is automatic activation enabled for LDAP authenticated users?
    def ldap_auto_activate?
      ldap_auto_activate.to_s.to_i != 0
    end

    ##
    # Converts the configuration to a hash.
    def to_h
      {
          enable_db_auth: enable_db_auth?,
          enable_ldap_auth: enable_ldap_auth?,
          ldap_host: ldap_host.to_s,
          ldap_port: ldap_port.to_s.to_i,
          ldap_ssl: ldap_ssl?,
          ldap_base_dn: ldap_base_dn.to_s,
          ldap_browse_user: ldap_browse_user.to_s,
          ldap_browse_password: ldap_browse_password.to_s,
          ldap_auto_activate: ldap_auto_activate?,
          ldap_system_admin_groups: ldap_system_admin_groups.to_s,
      }
    end

    ##
    # Saves the configuration (encrypted) to the SystemConfig.
    def save
      SystemConfig.set :auth, to_h, true
    end

    ##
    # Loads the configuration from the SystemConfig.
    def AuthConfig.load
      AuthConfig.new(SystemConfig.get(:auth) || {})
    end

  end
end
