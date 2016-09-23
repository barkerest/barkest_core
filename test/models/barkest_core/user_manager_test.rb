require 'test_helper'
module BarkestCore
  class UserManagerTest < ActiveSupport::TestCase

    def setup
      @user = users(:standard)
      @cfg = BarkestCore.auth_config
      @db_only = BarkestCore::UserManager.new(@cfg.merge({enable_ldap_auth: false, enable_db_auth: true}))
      @ldap_only = @cfg[:enable_ldap_auth] ? BarkestCore::UserManager.new(@cfg.merge({enable_db_auth: false})) : nil
    end

    test 'should be able to authenticate with default admin for db-only' do
      assert @db_only.authenticate( @user.email, 'password', '0.0.0.0' )
    end

    test 'should not be able to authenticate with default admin for ldap-only' do
      skip 'LDAP not configured.' unless @ldap_only
      assert_not @ldap_only.authenticate( 'admin@barkerest.com', 'Password1', '0.0.0.0' )
    end

    test 'should be able to login with test credentials for ldap-only' do
      skip 'LDAP not configured.' unless @ldap_only
      skip 'Missing :ldap_test_email or :ldap_ldap_password configuration.' if @cfg[:ldap_test_email].blank? || @cfg[:ldap_test_password].blank?
      assert @ldap_only.authenticate(@cfg[:ldap_test_email], @cfg[:ldap_test_password], '0.0.0.0' )
    end

    test 'should not be able to login with test credentials for db-only' do
      skip 'LDAP not configured.' unless @ldap_only
      skip 'Missing :ldap_test_email or :ldap_test_password configuration.' if @cfg[:ldap_test_email].blank? || @cfg[:ldap_test_password].blank?
      assert_not @db_only.authenticate(@cfg[:ldap_test_email], @cfg[:ldap_test_password], '0.0.0.0' )
    end

  end
end
