require 'test_helper'

class BarkestCoreTest < ActiveSupport::TestCase

  test 'should be able to request restart' do
    assert_not BarkestCore.restart_pending?
    BarkestCore.request_restart
    assert BarkestCore.restart_pending?
  end

  test 'should be able to add key gem patterns' do
    assert BarkestCore.add_key_gem_pattern 'something'
    assert BarkestCore.add_key_gem_pattern( /^something/ )
  end

  test 'should be able to list key gems' do
    list = BarkestCore.gem_list
    assert_not list.blank?
    # key gems should include 'rails'
    assert list.find {|v| v[0] == 'rails'}
  end

  test 'should be able to set auth_config defaults' do
    # get the defaults and make sure they are set.
    cfg = BarkestCore.auth_config_defaults(nil)
    assert_not_nil cfg
    assert_not cfg.keys.include?(:something)

    # change the defaults and ensure our key is set.
    cfg = BarkestCore.auth_config_defaults(something: :else)
    assert cfg.keys.include?(:something)

    # get the defaults and ensure our key is still set.
    cfg = BarkestCore.auth_config_defaults(nil)
    assert cfg.keys.include?(:something)
  end

  test 'should be able to set email_config defaults' do
    # get the defaults and make sure they are set.
    cfg = BarkestCore.email_config_defaults(nil)
    assert_not_nil cfg
    assert_not cfg.keys.include?(:something)

    # change the defaults and ensure our key is set.
    cfg = BarkestCore.email_config_defaults(something: :else)
    assert cfg.keys.include?(:something)

    # get the defaults and ensure our key is still set.
    cfg = BarkestCore.email_config_defaults(nil)
    assert cfg.keys.include?(:something)
  end

  test 'should be able to register db_config defaults' do
    # needs a db_name
    assert_not BarkestCore.register_db_config_defaults(nil, nil)
    assert_not BarkestCore.register_db_config_defaults('', nil)
    assert_not BarkestCore.register_db_config_defaults(:"", nil)
    assert_not BarkestCore.register_db_config_defaults('  ', nil)
    assert_not BarkestCore.register_db_config_defaults(:"  ", nil)

    # can't register for barkest_core
    assert_not BarkestCore.register_db_config_defaults(:barkest_core, nil)
    assert_not BarkestCore.register_db_config_defaults('barkest_core', nil)

    # can register for anything else
    assert BarkestCore.register_db_config_defaults(:something, nil)
    assert BarkestCore.register_db_config_defaults('something', nil)
    assert BarkestCore.register_db_config_defaults(:something, value: true, adapter: :none)
    assert BarkestCore.register_db_config_defaults('something', value: false, adapter: :none)

  end

end
