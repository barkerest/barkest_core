module BarkestCore
  ##
  # This class defines the default behavior for mailers in this application.
  #
  class ApplicationMailerBase < ActionMailer::Base


    ##
    # Gets the default hostname for messages.
    def self.default_hostname
      @default_hostname ||= BarkestCore.email_config[:default_hostname]
    end

    ##
    # Gets the default sender for messages.
    def self.default_sender
      @default_sender ||= BarkestCore.email_config[:default_sender]
    end

    ##
    # Gets the default recipient for messages.
    def self.default_recipient
      @default_recipient ||= BarkestCore.email_config[:default_recipient]
    end

    default from: ApplicationMailerBase.default_sender, to: ApplicationMailerBase.default_recipient
    layout 'mailer'

  end
end