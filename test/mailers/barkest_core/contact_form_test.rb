require 'test_helper'

class BarkestCore::ContactFormTest < ActionMailer::TestCase
  def setup
    @msg = BarkestCore::ContactMessage.new(
        your_name: 'John Doe',
        your_email: 'jdoe@example.com',
        related_to: 'Other',
        subject: 'Hello world',
        body: 'Hello world from the contact form.',
        remote_ip: '127.0.0.1'
    )
  end

  test "contact" do
    mail = BarkestCore::ContactForm.contact(@msg)
    assert_equal @msg.full_subject, mail.subject

    assert_equal [BarkestCore::ContactForm.default_recipient], mail.to, 'Recipient is wrong.'
    assert_equal [BarkestCore::ContactForm.default_sender], mail.from, 'Sender is wrong.'

    assert_match @msg.your_name, mail.body.encoded
    assert_match @msg.your_email, mail.body.encoded
    assert_match @msg.body, mail.body.encoded
    assert_match @msg.remote_ip, mail.body.encoded
  end

end
