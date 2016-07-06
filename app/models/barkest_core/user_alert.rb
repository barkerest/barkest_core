module BarkestCore
  ##
  # This model provides informational alerts to the user.
  class UserAlert
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :message, :model

    validates :message, presence: true

    def type
      @type || :info
    end

    def type=(value)
      @type = value ? value.to_s.to_sym : nil
    end

    def view
      @view || 'generic_user_alert'
    end

    def view=(value)
      @view = value.blank? ? nil : value.to_s
    end

  end
end
