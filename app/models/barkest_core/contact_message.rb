module BarkestCore
  class ContactMessage
    include ActiveModel::Model
    include ActiveModel::Validations
    include BarkestCore::EmailTester

    attr_accessor :your_name, :your_email, :related_to, :subject, :body, :remote_ip

    validates :your_name, presence: true
    validates :your_email, presence: true, format: { with: VALID_EMAIL_REGEX }
    validates :related_to, presence: true
    validates :subject, presence: true, if: :need_subject?
    validates :body, presence: true

    def full_subject
      return related_to if subject.blank?
      "#{related_to}: #{subject}"
    end

    def send_message
      BarkestCore::ContactForm.contact(self).deliver_now
    end

    private

    def need_subject?
      related_to.to_s.downcase == 'other'
    end

  end
end