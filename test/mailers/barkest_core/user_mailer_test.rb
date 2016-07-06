require 'test_helper'

module BarkestCore
  class UserMailerTest < ActionMailer::TestCase

    def sender_address
      BarkestCore.email_config[:default_sender]
    end

    test 'account_activation' do
      user = users(:standard)
      user.activation_token = User.new_token
      mail = BarkestCore::UserMailer.account_activation(user: user)
      assert_equal 'Account activation', mail.subject
      assert_equal [user.email], mail.to
      assert_equal [sender_address], mail.from
      assert_match user.name, mail.body.encoded
      assert_match user.activation_token, mail.body.encoded
      assert_match CGI::escape(user.email), mail.body.encoded
    end

    test 'password_reset' do
      user = users(:standard)
      user.reset_token = User.new_token
      mail = BarkestCore::UserMailer.password_reset(user: user)
      assert_equal 'Password reset request', mail.subject
      assert_equal [user.email], mail.to
      assert_equal [sender_address], mail.from
      assert_match user.reset_token, mail.body.encoded
      assert_match CGI::escape(user.email), mail.body.encoded
    end

    test 'invalid_password_reset' do
      email = 'sombody@example.com'
      mail = BarkestCore::UserMailer.invalid_password_reset(email: email)
      assert_equal 'Password reset request', mail.subject
      assert_equal [email], mail.to
      assert_equal [sender_address], mail.from
      assert_match email, mail.body.encoded
    end

  end
end
