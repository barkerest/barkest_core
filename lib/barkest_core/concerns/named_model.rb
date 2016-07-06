
module BarkestCore

  ##
  # Defines a few extensions to models that have unique names.
  #
  # If the unique field is named :name then you don't have to do
  # anything more than include this file.  For other unique fields
  # simply define +UNIQUE_STRING_FIELD+ to the name of the unique
  # field as either a symbol or a string.
  module NamedModel
    # :nodoc:
    def self.included(base)

      base.class_eval do

        private

        def self.unique_string_field
          @unique_string_field ||= const_defined?(:UNIQUE_STRING_FIELD) ? const_get(:UNIQUE_STRING_FIELD).to_sym : :name
        end

        public

        ##
        # Locates the model from ID or name.
        def self.get(value)
          if value.is_a?(Numeric)
            self.find_by(id: value)
          elsif value.is_a?(String)
            self.where("LOWER(\"#{table_name}\".\"#{unique_string_field}\")=?", value.downcase).first
          elsif value.is_a?(Symbol)
            self.where("LOWER(\"#{table_name}\".\"#{unique_string_field}\")=?", value.to_s.downcase).first ||
                self.where("LOWER(\"#{table_name}\".\"#{unique_string_field}\")=?", value.to_s.humanize.downcase).first
          elsif value.class == self
            value
          else
            nil
          end
        end

        ##
        # Gets the name of this model.
        def to_s
          send( self.class.unique_string_field )
        end

        ##
        # Tests for equality on ID or name.
        def ==(other)
          if other.is_a?(Numeric)
            id == other
          elsif other.is_a?(String)
            send( self.class.unique_string_field ).to_s.downcase == other.downcase
          elsif other.is_a?(self.class)
            id == other.id
          else
            other = self.class.get(other)
            other ? id == other.id : false
          end
        end

      end

    end

  end
end