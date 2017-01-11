require 'test_helper'

class ExtraPartialTest < ActionDispatch::IntegrationTest

  test 'should not have templates' do
    get root_url
    assert_template partial: 'layouts/barkest_core/_subheader', count: 0
  end

  test 'should have subheader template' do
    get barkest_core_testsub_page1_url
    assert_template 'layouts/barkest_core/_subheader'
  end

  test 'should allow partial registration' do
    partial = 'layouts/barkest_core/menu_sample'
    template = 'layouts/barkest_core/_menu_sample'

    # shouldn't be registered yet, so count should be zero.
    get root_url
    assert_template partial: template, count: 0

    BarkestCore.register_footer_menu partial
    get root_url
    assert_template partial: template, count: 1

    BarkestCore.register_anon_menu partial
    get root_url
    assert_template partial: template, count: 2

    BarkestCore.register_auth_menu partial
    get root_url
    assert_template partial: template, count: 2   # nobody is logged in, count should still be 2

    log_in_as users(:standard)
    get root_url
    assert_template partial: template, count: 3
  end


end