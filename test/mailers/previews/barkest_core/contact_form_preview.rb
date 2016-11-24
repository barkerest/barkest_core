# Preview all emails at http://localhost:3000/rails/mailers/barkest_core/contact_form
class BarkestCore::ContactFormPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/barkest_core/contact_form/contact
  def contact
    msg = BarkestCore::ContactMessage.new(
        your_name: 'John Doe',
        your_email: 'jdoe@example.com',
        related_to: 'Other',
        subject: 'Hello world',
        body: 'Hello world from the contact form.',
        remote_ip: '127.0.0.1'
    )
    BarkestCore::ContactForm.contact msg
  end

end
