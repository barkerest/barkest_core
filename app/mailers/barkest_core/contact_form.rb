require_dependency 'barkest_core/application_mailer_base.rb'

class BarkestCore::ContactForm < ::BarkestCore::ApplicationMailerBase

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.barkest_core.contact_form.contact.subject
  #
  def contact(msg)
    @data = {
        msg: msg,
        client_ip: msg.remote_ip,
        gems: BarkestCore.gem_list(Rails.application.class.parent_name.underscore, 'rails', 'barkest*'),
    }
    mail subject: msg.full_subject #, reply_to: msg.your_email
  end

end
