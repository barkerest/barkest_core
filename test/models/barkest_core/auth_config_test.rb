require 'test_helper'

module BarkestCore
  class AuthConfigTest < ActiveSupport::TestCase
    def setup
      @item = BarkestCore::AuthConfig.new(enable_db_auth: true)
      @item2 = BarkestCore::AuthConfig.new(
          enable_ldap_auth: true,
          ldap_host: 'localhost',
          ldap_port: 389,
          ldap_base_dn: 'DC=localhost',
          ldap_browse_user: 'xyz',
          ldap_browse_password: 'abc',
          ldap_system_admin_groups: 'none'
      )

    end

    test 'should be valid' do
      assert @item.valid?
      assert @item2.valid?
    end

    test 'should require enable_x_auth' do
      @item.enable_db_auth = false
      assert_not @item.valid?
      @item2.enable_ldap_auth = false
      assert_not @item.valid?
    end

    test 'should require ldap_host' do
      assert_required @item2, :ldap_host
    end

    test 'should require ldap_port' do
      assert_required @item2, :ldap_port
    end

    test 'should require ldap_base_dn' do
      assert_required @item2, :ldap_base_dn
    end

    test 'should require ldap_browse_user' do
      assert_required @item2, :ldap_browse_user
    end

    test 'should require ldap_browse_password' do
      assert_required @item2, :ldap_browse_password
    end

    test 'should require ldap_system_admin_groups' do
      assert_required @item2, :ldap_system_admin_groups
    end


  end
end