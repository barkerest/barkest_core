BarkestCore::InstallGenerator.class_eval do
  ##
  # Configures the authorization system.
  def configure_auth
    config_file = 'config/auth.yml'

    attributes = [
        [ 'enable_ldap_auth', :ask_for_bool ],
        [ 'enable_db_auth', :ask_for_bool ],
        {
            true => [
                [ 'ldap_host', :ask_for_string, nil, nil, 'ldap-server.example.com' ],
                [ 'ldap_port', :ask_for_int, (1..65535), nil, 389 ],
                [ 'ldap_base_dn', :ask_for_string, nil, nil, 'dc=ldap,dc=example,dc=com' ],
                [ 'ldap_ssl', :ask_for_string, %w(simple_tls start_tls true false), nil, 'true' ],
                [ 'ldap_browse_user', :ask_for_string ],
                [ 'ldap_browse_password', :ask_for_secret ],
                [ 'ldap_auto_activate', :ask_for_bool, nil, 'ldap_auto_activate (on first login)', true ],
                [ 'ldap_system_admin_groups', :ask_for_string, nil, nil, 'domain admins' ]
            ]
        }
    ]

    default = {
        'enable_ldap_auth' => false,
        'enable_db_auth' => true
    }

    configure_the 'authentication system', config_file, attributes, 'enable_ldap_auth', default
  end
end