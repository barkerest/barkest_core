module BarkestCore
  ##
  # This module will add boolean parsing functions to a class.
  #
  module BooleanParser

    ##
    # :stopdoc:
    def self.included(base)
      base.class_eval do

       ##
       # :startdoc:

        protected

        ##
        # Parses for a 3-way boolean.
        #
        # If the value is nil, then nil is returned.
        # If the value is 'true', 'yes', 'on', '1', 't', or 'y' then true is returned.
        # Otherwise false is returned.
        #
        def self.parse_for_boolean_column(value)
          return nil if value.nil?
          value = value.to_s.downcase
          %w(true yes on 1 t y).include? value
        end

        ##
        # Parses the value for a 3-way SQL filter.
        #
        # If the value is nil, then 'NULL' is returned.
        # If the value parses to true, then '1' is returned.
        # Otherwise '0' is returned.
        #
        def self.parse_for_boolean_filter(value)
          value = parse_for_boolean_column(value)
          return 'NULL' if value.nil?
          value ? '1' : '0'
        end

      end
    end

  end
end
