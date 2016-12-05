class ContactTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @msg = {
        your_name: 'John Smith',
        your_email: 'john.smith@example.com',
        related_to: 'Other',
        subject: 'Just a thought',
        body: 'I just wanted to reach out and say hi.',
    }
  end

  access_tests_for :index,
                   url_helper: 'contact_path',
                   allow_anon: true,
                   allow_any_user: true

  test 'valid contact message' do
    get contact_path
    assert_template 'contact/index'

    post contact_path, barkest_core_contact_message: @msg

    assert_redirected_to root_url
    follow_redirect!

    assert_not flash.empty?
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test 'alternate valid contact message' do
    get contact_path
    assert_template 'contact/index'

    @msg[:related_to] = 'General Message'
    @msg.delete(:subject)

    post contact_path, barkest_core_contact_message: @msg

    assert_redirected_to root_url
    follow_redirect!

    assert_not flash.empty?
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test 'invalid contact message' do
    get contact_path
    assert_template 'contact/index'

    # body is required
    post contact_path, barkest_core_contact_message: @msg.except(:body)
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    # subject is required if 'related_to' is 'other'
    post contact_path, barkest_core_contact_message: @msg.except(:subject)
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    # related_to is required
    post contact_path, barkest_core_contact_message: @msg.except(:related_to)
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    # your_email is required
    post contact_path, barkest_core_contact_message: @msg.except(:your_email)
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    # your_email must be valid.
    post contact_path, barkest_core_contact_message: @msg.merge(your_email: 'invalid')
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    post contact_path, barkest_core_contact_message: @msg.merge(your_email: 'invalid@localhost')
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    # your_name is required
    post contact_path, barkest_core_contact_message: @msg.except(:your_name)
    assert_template 'contact/index'
    assert_select 'div#error_explanation'

    # just for good measure, make sure the base @msg value is still good.
    # if it is not then the previous tests are all invalid.
    # so this final test must pass to validate the prior tests.
    post contact_path, barkest_core_contact_message: @msg
    assert_redirected_to root_url

    # and after all those tests, there should be exactly one message that was processed.
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

end