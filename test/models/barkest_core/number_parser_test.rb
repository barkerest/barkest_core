require 'test_helper'

module BarkestCore
  class NumberParserTest < ActiveSupport::TestCase

    test 'should parse valid numbers' do
      {
          '0' => 0.0, '123' => 123.0, '123.4' => 123.4, '12345' => 12345.0, '12,345' => 12345.0, '12,345.678' => 12345.678, '1,234,567' => 1234567.0,
          '-123' => -123.0, '-123.4' => -123.4, '-12345' => -12345.0, '-12,345' => -12345.0, '-12,345.678' => -12345.678, '-1,234,567' => -1234567.0,
          '+123' => 123.0, '+123.4' => 123.4, '+12345' => 12345.0, '+12,345' => 12345.0, '+12,345.678' => 12345.678, '+1,234,567' => 1234567.0,
      }.each do |k,v|
        assert_equal v, BarkestCore::NumberParser.parse_for_float_column(k), "#{k} should be a valid float"
        assert_equal v.to_i, BarkestCore::NumberParser.parse_for_int_column(k), "#{k} should be a valid int"
        assert_equal v, BarkestCore::NumberParser.parse_for_float_filter(k).to_f, "#{k} should be a valid float filter"
        assert_equal v.to_i, BarkestCore::NumberParser.parse_for_int_filter(k).to_i, "#{k} should be a valid int filter"
      end
    end

    test 'should parse nil values' do
      [ nil, '', '  ' ].each do |v|
        assert_nil BarkestCore::NumberParser.parse_for_float_column(v), "#{v.inspect} should not be a valid float"
        assert_nil BarkestCore::NumberParser.parse_for_int_column(v), "#{v.inspect} should not be a valid int"
        assert_equal "NULL", BarkestCore::NumberParser.parse_for_float_filter(v), "#{v.inspect} should be a NULL float filter"
        assert_equal "NULL", BarkestCore::NumberParser.parse_for_int_filter(v), "#{v.inspect} should be a NULL int filter"
      end
    end

  end
end