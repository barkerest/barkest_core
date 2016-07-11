module BarkestCore
  ##
  # This module will add number parsing methods to a class.
  #
  module NumberParser

    ##
    # This regular expression should match any non-exponential numeric value.
    NUMBER_REGEX = /^-?([0-9]+,)*[0-9]+(\.[0-9]+)?$/

    ##
    # :stopdoc:
    def self.included(base)
      base.class_eval do

        ##
        # :startdoc:
        protected

        ##
        # Parses a value for storage in a float column.
        #
        # Returns nil if the value is invalid.
        # Otherwise it returns a float.
        #
        def self.parse_for_float_column(value)
          value = value.to_s
          return nil unless NUMBER_REGEX.match(value)
          value.blank? ? nil : value.split(',').join.to_f
        end

        ##
        # Parses a value for storage in an integer column.
        #
        # Returns nil if the value is invalid.
        # Otherwise it returns an integer.
        def self.parse_for_int_column(value)
          value = value.to_s
          return nil unless NUMBER_REGEX.match(value)
          value.blank? ? nil : value.split(',').join.to_i
        end

        ##
        # Parses a value for use as a SQL filter.
        #
        # Returns 'NULL' if the value parses to nil.
        # Otherwise returns the value.
        #
        def self.parse_for_float_filter(value)
          value = parse_for_float_column(value)
          value.nil? ? 'NULL' : value.to_s
        end

        ##
        # Parses a value for use as a SQL filter.
        #
        # Returns 'NULL' if the value parses to nil.
        # Otherwise returns the value.
        #
        def self.parse_for_int_filter(value)
          value = parse_for_int_column(value)
          value.nil? ? 'NULL' : value.to_s
        end

      end
    end

  end
end
