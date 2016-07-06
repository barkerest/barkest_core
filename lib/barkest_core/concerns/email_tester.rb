require 'resolv'

module BarkestCore

  ##
  # Adds helper methods to the model to allow verifying email addresses.
  module EmailTester

    ##
    # A regex that can be used to verify most email addresses.
    #
    # When used, the match will include a USER and DOMAIN element to represent the broken down email address.
    VALID_EMAIL_REGEX = /\A(?<USER>[\w+\-.]+)@(?<DOMAIN>[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+)\z/i

    ##
    # Validates the supplied email address against the VALID_EMAIL_REGEX.
    #
    # The +check_dns+ option ensures that an MX record can be found for the email address.
    def self.valid_email?(email, check_dns = false)
      match = VALID_EMAIL_REGEX.match(email)
      return false unless match
      if check_dns
        return false if Resolv::DNS.open{ |dns| dns.getresources match['DOMAIN'], Resolv::DNS::Resource::IN::MX }.blank?
      end
      true
    end

    # :nodoc:
    def self.included(base)
      base.class_eval do

        protected

        ##
        # Validates the supplied email address against the VALID_EMAIL_REGEX.
        #
        # The +check_dns+ option ensures that an MX record can be found for the email address.
        def valid_email?(email, check_dns = false)
          BarkestCore::EmailTester.valid_email? email, check_dns
        end

      end
    end
  end
end