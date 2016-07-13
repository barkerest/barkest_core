require 'test_helper'

module BarkestCore
  class MsSqlDefinitionTest < ActiveSupport::TestCase

    VALID_LIST = [
        ['XYZ',     'VIEW', 'CREATE VIEW [XYZ] AS SELECT 123 AS [VALUE]'],
        ['XYZ_123', 'VIEW', 'CREATE VIEW XYZ_123 AS SELECT \'ABC\'\'XYZ\' AS [123]'],
        ['ABC',     'VIEW', "-- This is a comment about this view.\nCREATE VIEW [ABC] AS SELECT 1 AS [VALUE]\n/* Just a simple comment. */"],
        ['ABC_123', 'VIEW', "CREATE VIEW ABC_123 AS SELECT 1 AS [Index]\nUNION SELECT 2\nUNION SELECT 3\n-- This is not a drop statement."],

        ['AEIOU',   'FUNCTION', 'CREATE FUNCTION [AEIOU] (num AS INTEGER) RETURNS TABLE AS SELECT ISNULL(num,0) * 5 AS [five_times_more]'],
    ]

    INVALID_LIST = [
        [
            BarkestCore::MsSqlDefinition::EmptyDefinition,
            ''
        ],
        [
            BarkestCore::MsSqlDefinition::EmptyDefinition,
            "-- This is a comment\n-- This is another comment\n/* And a final comment.\nNote that this definition still has no content.\n/* We should also support embedded comments */ because they may occur. */"
        ],
        [
            BarkestCore::MsSqlDefinition::MissingCreateStatement,
            'SELECT 1 AS Value'
        ],
        [
            BarkestCore::MsSqlDefinition::MissingCreateStatement,
            'CREATE TABLE XYZ (ID INTEGER PRIMARY KEY, NAME VARCHAR(100))'
        ],
        [
            BarkestCore::MsSqlDefinition::ExtraDDL,
            "CREATE VIEW XYZ AS SELECT 1 AS [Value]\nCREATE VIEW ABC AS SELECT 2 AS [Value]"
        ],
        [
            BarkestCore::MsSqlDefinition::ExtraDDL,
            "create view xyz as select 1 as [value]\ndrop view xyz"
        ],
        [
            BarkestCore::MsSqlDefinition::UnmatchedBracket,
            'create view xyz as select 1 as [value, 2 as [another_value]'
        ],
        [
            BarkestCore::MsSqlDefinition::UnmatchedBracket,
            'create view xyz as select 1 as [value]]'
        ],
        [
            BarkestCore::MsSqlDefinition::UnclosedQuote,
            "create view xyz as select 'hello as [value]"
        ],
        [
            BarkestCore::MsSqlDefinition::UnclosedQuote,
            "create view xyz as select 'hello 'world' as value"
        ],
        [
            BarkestCore::MsSqlDefinition::UnclosedQuote,
            "create view xyz as select 1 as \"value"
        ],
        [
            BarkestCore::MsSqlDefinition::UnclosedQuote,
            "create view xyz as select 1 as value\""
        ],
        [
            BarkestCore::MsSqlDefinition::UnmatchedComment,
            'create view xyz as select 1 as value /* /* a comment that was opened twice */'
        ],
        [
            BarkestCore::MsSqlDefinition::UnmatchedComment,
            'create view xyz as select 1 as value /* a comment that is closed twice */ */'
        ],
    ]

    test 'should be valid samples' do
      VALID_LIST.each_with_index do |(name,type,sql), index|
        begin
          d = MsSqlDefinition.new(sql)
        rescue MsSqlDefinition::InvalidDefinition => e
          raise Minitest::Assertion, "Encountered #{e.class} error when processing statement #{index}."
        end
        assert_equal name, d.name, "Name mismatch error #{d.name.inspect} <> #{name.inspect} for statement #{index}."
        assert_equal type, d.type, "Type mismatch error #{d.type.inspect} <> #{type.inspect} for statement #{index}."
      end
    end

    test 'should be invalid samples' do
      INVALID_LIST.each_with_index do |(error,sql),index|
        assert_raises error, "Expected error of type #{error} for statement #{index}." do
          MsSqlDefinition.new(sql)
        end
      end
    end

  end
end
