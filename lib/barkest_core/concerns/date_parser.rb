module BarkestCore
  ##
  # This module will add date parsing functions to a class.
  #
  module DateParser

    ##
    # A simple hash that can be used to validate a date entry column.
    DATE_FORMAT = { with: /^(\d{1,2}\/\d{1,2}\/\d{4})?$/, multiline: true }

    ##
    # :stopdoc:
    def self.included(base)
      base.class_eval do

        ##
        # :startdoc:
        protected

        ##
        # Parses a value for storage in a date/datetime column.
        #
        # Value should be a string in 'M/D/YYYY' format but can also be a Date or Time object.
        #
        # Returns a Date object or nil if value is invalid.
        #
        def self.parse_for_date_column(value)
          value = value.to_s(:date4) if value && !value.is_a?(String) && value.respond_to?(:strftime)

          if value && value.is_a?(String)
            m,d,y = value.split('/')

            if m && d && y
              # 1940-1999, 2000 - 2039
              y = y.to_i(10)
              y = 2000 + y if y < 40
              y = 1900 + y if y < 100
              begin
                value = Time.new(y, m.to_i(10), d.to_i(10))
              rescue ArgumentError
                value = nil
              end
            else
              value = nil
            end
          else
            value = nil
          end

          value
        end

        ##
        # Parses a value for storage in a datetime column.
        #
        # Value should be a string in 'M/D/YYYY HH:MM:SS' format, but can also be a Date or Time object.
        #
        # Returns a Time object or nil if value is invalid.
        #
        def self.parse_for_time_column(value)
          value = value.strftime("%m/%d/%Y %H:%M:%S") if value && !value.is_a?(String) && value.respond_to?(:strftime)

          if value && value.is_a?(String)
            dt,tm = value.split(' ')

            # No date?
            if dt && !tm
              tm = dt
              dt = '1/1/1900'
            end

            m,d,y = dt.split('/')
            h,n,s = tm.split(':')
            h = '0' unless h
            n = '0' unless n
            s = '0' unless s
            if m && d && y
              # 1940-1999, 2000 - 2039
              y = y.to_i(10)
              y = 2000 + y if y < 40
              y = 1900 + y if y < 100
              begin
                value = Time.new(y, m.to_i(10), d.to_i(10), h.to_i(10), n.to_i(10), s.to_i(10))
              rescue ArgumentError
                value = nil
              end
            else
              value = nil
            end
          else
            value = nil
          end

          value
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

      end
    end

  end
end
