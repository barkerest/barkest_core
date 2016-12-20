module BarkestCore
  ##
  # This module will add consistent date parsing functions to a class.
  #
  module DateParser

    ##
    # A regular expression to parse either American format MM/DD/YYYY or ISO format YYYY-MM-DD dates.
    DATE_REGEX = /^(?:(?<M>\d{1,2})\/(?<D>\d{1,2})\/(?<Y>\d{2,4})|(?<Y>\d{2,4})-(?<M>\d{1,2})-(?<D>\d{1,2}))(?:\s.*)?$/

    ##
    # A regular expression to parse either American format MM/DD/YYYY or ISO format YYYY-MM-DD dates, but also allows for a blank value.
    NULLABLE_DATE_REGEX = /^(?:(?:(?<M>\d{1,2})\/(?<D>\d{1,2})\/(?<Y>\d{2,4})|(?<Y>\d{2,4})-(?<M>\d{1,2})-(?<D>\d{1,2}))(?:\s.*)?)?$/

    ##
    # A regular expression to parse either American format MM/DD/YYY HH:MM:SS or ISO format YYYY-MM-DD HH:MM:SS times.
    TIME_REGEX = /^(?:(?:(?<M>\d{1,2})\/(?<D>\d{1,2})\/(?<Y>\d{2,4})|(?<Y>\d{2,4})-(?<M>\d{1,2})-(?<D>\d{1,2}))\s+)?(?:(?<H>\d{1,2})\:(?<N>\d{1,2})(?:\:(?<S>\d{1,2}))?)(?:\s+(?<T>AM|PM).*)?$/i

    ##
    # A regular expression to parse either American format MM/DD/YYY HH:MM:SS or ISO format YYYY-MM-DD HH:MM:SS times, but also allows for a blank value.
    NULLABLE_TIME_REGEX = /^(?:(?:(?:(?<M>\d{1,2})\/(?<D>\d{1,2})\/(?<Y>\d{2,4})|(?<Y>\d{2,4})-(?<M>\d{1,2})-(?<D>\d{1,2}))\s+)?(?:(?<H>\d{1,2})\:(?<N>\d{1,2})(?:\:(?<S>\d{1,2}))?)(?:\s+(?<T>AM|PM).*)?)?$/i

    ##
    # A simple hash that can be used to validate a date entry column.
    #
    # validates :my_date, :format => DATE_FORMAT
    #
    DATE_FORMAT = { with: DATE_REGEX, multiline: true, message: 'must be in MM/DD/YYYY or YYYY-MM-DD format' }

    ##
    # A simple hash that can be used to validate a nullable date entry column.
    #
    # validates :my_date, :format => NULLABLE_DATE_FORMAT
    #
    NULLABLE_DATE_FORMAT = { with: NULLABLE_DATE_REGEX, multiline: true, message: 'must be in MM/DD/YYYY or YYYY-MM-DD format' }


    private_constant :DATE_REGEX, :TIME_REGEX, :NULLABLE_DATE_REGEX, :NULLABLE_TIME_REGEX

    ##
    # Parses a value for storage in a date/datetime column.
    #
    # Value should be a string in 'M/D/YYYY' or 'YYYY-MM-DD' format but can also be a Date or Time object.
    #
    # Returns a Time object or nil if value is invalid.
    #
    def self.parse_for_date_column(value)
      Time.utc_parse(value).date rescue nil
    end

    ##
    # Parses a value for storage in a datetime column.
    #
    # Value should be a string in 'M/D/YYYY HH:MM:SS' or 'YYYY-MM-DD HH:MM:SS' format, but can also be a Date or Time object.
    #
    # Returns a Time object or nil if value is invalid.
    #
    def self.parse_for_time_column(value)
      Time.utc_parse(value) rescue nil
    end

    ##
    # Parses a value for use in a SQL query.
    #
    # Returns NULL if the parsed date is nil.
    # Otherwise returns the date in 'YYYY-MM-DD' format.
    #
    def self.parse_for_date_filter(value)
      value = parse_for_date_column(value)
      return 'NULL' unless value
      value.strftime('\'%Y-%m-%d\'')
    end

    ##
    # Parses a value for use in a SQL query.
    #
    # Returns NULL if the parsed time is nil.
    # Otherwise returns the time in 'YYYY-MM-DD HH:MM:SS' format.
    #
    def self.parse_for_time_filter(value)
      value = parse_for_time_column(value)
      return 'NULL' unless value
      value.strftime('\'%Y-%m-%d %H:%M:%S\'')
    end

    # :nodoc:
    def self.included(base)
      base.class_eval do

        ##
        # Parses a value for storage in a date/datetime column.
        #
        # Value should be a string in 'M/D/YYYY' or 'YYYY-MM-DD' format but can also be a Date or Time object.
        #
        # Returns a Time object or nil if value is invalid.
        #
        def self.parse_for_date_column(value)
          BarkestCore::DateParser.parse_for_date_column value
        end

        ##
        # Parses a value for storage in a datetime column.
        #
        # Value should be a string in 'M/D/YYYY HH:MM:SS' or 'YYYY-MM-DD HH:MM:SS' format, but can also be a Date or Time object.
        #
        # Returns a Time object or nil if value is invalid.
        #
        def self.parse_for_time_column(value)
          BarkestCore::DateParser.parse_for_time_column value
        end

        ##
        # Parses a value for use in a SQL query.
        #
        # Returns NULL if the parsed date is nil.
        # Otherwise returns the date in 'YYYY-MM-DD' format.
        #
        def self.parse_for_date_filter(value)
          BarkestCore::DateParser.parse_for_date_filter value
        end

        ##
        # Parses a value for use in a SQL query.
        #
        # Returns NULL if the parsed time is nil.
        # Otherwise returns the time in 'YYYY-MM-DD HH:MM:SS' format.
        #
        def self.parse_for_time_filter(value)
          BarkestCore::DateParser.parse_for_time_filter value
        end

      end
    end


    protected

    ##
    # Parses a value for storage in a date/datetime column.
    #
    # Value should be a string in 'M/D/YYYY' or 'YYYY-MM-DD' format but can also be a Date or Time object.
    #
    # Returns a Time object or nil if value is invalid.
    #
    def parse_for_date_column(value)
      BarkestCore::DateParser.parse_for_date_column value
    end

    ##
    # Parses a value for storage in a datetime column.
    #
    # Value should be a string in 'M/D/YYYY HH:MM:SS' or 'YYYY-MM-DD HH:MM:SS' format, but can also be a Date or Time object.
    #
    # Returns a Time object or nil if value is invalid.
    #
    def parse_for_time_column(value)
      BarkestCore::DateParser.parse_for_time_column value
    end

    ##
    # Parses a value for use in a SQL query.
    #
    # Returns NULL if the parsed date is nil.
    # Otherwise returns the date in 'YYYY-MM-DD' format.
    #
    def parse_for_date_filter(value)
      BarkestCore::DateParser.parse_for_date_filter value
    end

    ##
    # Parses a value for use in a SQL query.
    #
    # Returns NULL if the parsed time is nil.
    # Otherwise returns the time in 'YYYY-MM-DD HH:MM:SS' format.
    #
    def parse_for_time_filter(value)
      BarkestCore::DateParser.parse_for_time_filter value
    end

  end
end
