# Preview all emails at http://localhost:3000/rails/mailers/barkest_core/contact_form
class BarkestCore::ContactFormPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/barkest_core/contact_form/contact
  def contact
    BarkestCore::ContactForm.contact
  end

end
