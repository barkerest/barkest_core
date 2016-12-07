require 'test_helper'

module BarkestCore
  class BoolParserTest < ActiveSupport::TestCase

    test 'should parse true values' do
      %w(TRUE true True YES yes Yes ON on On 1 -1 T t Y y).each do |val|
        assert BarkestCore::BooleanParser.parse_for_boolean_column(val), "#{val.inspect} should be true"
        assert_equal "1", BarkestCore::BooleanParser.parse_for_boolean_filter(val), "#{val.inspect} should be true"
      end
    end

    test 'should parse false values' do
      %w(FALSE false False NO no No OFF off Off 0 F f N n).each do |val|
        assert_not BarkestCore::BooleanParser.parse_for_boolean_column(val), "#{val.inspect} should be false"
        assert_equal "0", BarkestCore::BooleanParser.parse_for_boolean_filter(val), "#{val.inspect} should be false"
      end
    end

    test 'should parse nil values' do
      [ nil, '', '   ' ].each do |val|
        assert_nil BarkestCore::BooleanParser.parse_for_boolean_column(val), "#{val.inspect} should be nil"
        assert_equal "NULL", BarkestCore::BooleanParser.parse_for_boolean_filter(val), "#{val.inspect} should be nil"
      end
    end

  end
end