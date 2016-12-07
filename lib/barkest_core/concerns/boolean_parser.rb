module BarkestCore
  ##
  # This module will add boolean parsing functions to a class.
  #
  module BooleanParser

    ##
    # Parses for a 3-way boolean.
    #
    # If the value is nil, then nil is returned.
    # If the value is 'true', 'yes', 'on', '1', 't', or 'y' then true is returned.
    # Otherwise false is returned.
    #
    def self.parse_for_boolean_column(value)
      return nil if value.to_s.blank?
      value = value.to_s.downcase
      %w(true yes on 1 -1 t y).include? value
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

    # :nodoc:
    def self.included(base)
      base.class_eval do

        ##
        # Parses for a 3-way boolean.
        #
        # If the value is nil, then nil is returned.
        # If the value is 'true', 'yes', 'on', '1', 't', or 'y' then true is returned.
        # Otherwise false is returned.
        #
        def self.parse_for_boolean_column(value)
          BarkestCore::BooleanParser.parse_for_boolean_column value
        end

        ##
        # Parses the value for a 3-way SQL filter.
        #
        # If the value is nil, then 'NULL' is returned.
        # If the value parses to true, then '1' is returned.
        # Otherwise '0' is returned.
        #
        def self.parse_for_boolean_filter(value)
          BarkestCore::BooleanParser.parse_for_boolean_filter value
        end

      end
    end


    protected

    ##
    # Parses for a 3-way boolean.
    #
    # If the value is nil, then nil is returned.
    # If the value is 'true', 'yes', 'on', '1', 't', or 'y' then true is returned.
    # Otherwise false is returned.
    #
    def parse_for_boolean_column(value)
      BarkestCore::BooleanParser.parse_for_boolean_column value
    end

    ##
    # Parses the value for a 3-way SQL filter.
    #
    # If the value is nil, then 'NULL' is returned.
    # If the value parses to true, then '1' is returned.
    # Otherwise '0' is returned.
    #
    def parse_for_boolean_filter(value)
      BarkestCore::BooleanParser.parse_for_boolean_filter value
    end

  end
end
