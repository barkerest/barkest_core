module BarkestCore
  ##
  # Contains some miscellaneous helper methods.
  module MiscHelper

    ##
    # Formats a date in M/D/YYYY format.
    #
    # The +date+ can be either a string already in the correct format, or a Date/Time object.
    # If +date+ is blank or nil, then nil will be returned.
    #
    def fmt_date(date)
      return nil if date.blank?
      return nil unless (date.is_a?(String) || date.is_a?(Date) || date.is_a?(Time))
      unless date.is_a?(String)
        date = date.to_s(:date4)
      end
      m,d,y = date.split('/')
      "#{m.to_i}/#{d.to_i}/#{y.to_i}"
    end

    ##
    # Formats a number to the specified number of decimal places.
    #
    # The +value+ can be either any valid numeric expression that can be converted to a float.
    #
    def fixed(value, places = 2)
      value = value.to_s.to_f unless value.is_a?(Float)
      sprintf("%0.#{places}f", value.round(places))
    end

    ##
    # Splits a name into First, Middle, and Last parts.
    #
    # Returns an array containing [ First, Middle, Last ]
    # Any part that is missing will be nil.
    #
    #   'John Doe'          => [ 'John', nil, 'Doe' ]
    #   'Doe, John'         => [ 'John', nil, 'Doe' ]
    #   'John A. Doe'       => [ 'John', 'A.', 'Doe' ]
    #   'Doe, John A.'      => [ 'John', 'A.', 'Doe' ]
    #   'John A. Doe Jr.'   => [ 'John', 'A.', 'Doe Jr.' ]
    #   'Doe Jr., John A.'  => [ 'John', 'A.', 'Doe Jr.' ]
    #
    # Since it doesn't check very hard, there are some known bugs as well.
    #
    #   'John Doe Jr.'      => [ 'John', 'Doe', 'Jr.' ]
    #   'John Doe, Jr.'     => [ 'Jr.', nil, 'John Doe' ]
    #   'Doe, John A., Jr.' => [ 'John', 'A., Jr.', 'Doe' ]
    #
    # It should work in most cases.
    #
    def split_name(name)
      name ||= ''
      if name.include?(',')
        last,first = name.split(',', 2)
        first,middle = first.to_s.strip.split(' ', 2)
      else
        first,middle,last = name.split(' ', 3)
        if middle && !last
          middle,last = last,middle
        end
      end
      [ first.to_s.strip, middle.to_s.strip, last.to_s.strip ]
    end

  end
end
