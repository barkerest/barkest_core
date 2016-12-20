require 'active_record'

module BarkestCore
  module UtcConversion
    class UtcConverter < DelegateClass(ActiveRecord::Type::Value)
      include ActiveRecord::Type::Decorator

      def type_cast_from_database(value)
        convert_to_utc(value)
      end

      def type_cast_from_user(value)
        convert_to_utc(value)
      end

      def convert_to_utc(value)
        if value.is_a?(Array)
          value.map { |v| convert_to_utc(v) }
        else
          Time.utc_parse(value) rescue nil
        end
      end

    end

    extend ActiveSupport::Concern

    included do
      self.time_zone_aware_attributes = false if self.respond_to?(:time_zone_aware_attributes=)
    end

    module ClassMethods
      private

      def inherited(subclass)
        subclass.class_eval do
          matcher = ->(name, type) { create_utc_conversion_attribute?(name, type) }
          decorate_matching_attribute_types(matcher, :_utc_conversion) do |type|
            UtcConverter.new(type)
          end
        end
        super
      end

      # disable TimeZoneConversion
      def create_time_zone_conversion_attribute?(name, cast_type)
        false
      end

      # enable UtcConversion
      def create_utc_conversion_attribute?(name, cast_type)
        cast_type.type == :datetime
      end
    end

  end
end

# add it to the base model.
ActiveRecord::Base.include BarkestCore::UtcConversion