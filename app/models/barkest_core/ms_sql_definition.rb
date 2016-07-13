module BarkestCore
  class MsSqlDefinition
    InvalidDefinition       = Class.new(StandardError)

    EmptyDefinition         = Class.new(InvalidDefinition)
    MissingCreateStatement  = Class.new(InvalidDefinition)
    ExtraDDL                = Class.new(InvalidDefinition)
    UnmatchedBracket        = Class.new(InvalidDefinition)
    UnclosedQuote           = Class.new(InvalidDefinition)
    UnmatchedComment        = Class.new(InvalidDefinition)

    attr_reader :name, :type, :definition

    def initialize(raw_sql)

      raw_sql = raw_sql.to_s.lstrip
      # strip leading comment lines.
      while raw_sql[0...2] == '--' || raw_sql[0...2] == '/*'
        if raw_sql[0...2] == '--'
          # trim off the first line.
          raw_sql = raw_sql.partition("\n")[2].to_s.lstrip
        else
          # find the first */ sequence in the string.
          comment_end = raw_sql.index('*/')
          raise UnmatchedComment, 'raw_sql starts with "/*" sequence with no matching "*/" sequence' unless comment_end

          # find the last /* sequence before that.
          comment_start = raw_sql.rindex('/*', comment_end)

          # remove this comment
          raw_sql = (raw_sql[0...comment_start].to_s + raw_sql[(comment_end + 2)..-1].to_s).lstrip
        end
      end

      raise EmptyDefinition, 'raw_sql contains no data' if raw_sql.blank?

      # first line should be CREATE VIEW|FUNCTION|PROCEDURE "XYZ"
      regex = /^CREATE\s+(?<TYPE>VIEW|FUNCTION|PROCEDURE)\s+\[?(?<NAME>[A-Z][A-Z0-9_]*)\]?\s+(?<DEFINITION>.*)$/im
      match = regex.match(raw_sql)

      raise MissingCreateStatement, 'raw_sql must contain a "CREATE VIEW|FUNCTION|PROCEDURE" statement' unless match

      @name = match['NAME']
      @type = match['TYPE']
      @definition = match['DEFINITION']

      # we're going to test the definition loosely.
      # so first we'll get rid of all valid literals and comments.
      # this will leave behind mangled invalid SQL, but we can use it to determine if there are any simple issues.
      # all removed components are replaced by single spaces to ensure that the remaining components are separate from
      # each other.
      test_sql = match['DEFINITION']
                     .gsub(/\s+/,' ')   # condense whitespace
                     .split(/(?:(?:'[^']*')|(?:"[^"]*")|(?:\[[^\[\]]*\]))/m).join(' ') # remove all quoted literals '', "", and []
                     .split(/--[^\r\n]*/).join(' ')                         # remove all single-line comments

      # remove all multi-line comments
      # the regex will find matches for all of the innermost multi-line comments.
      regex = /\/\*(?:(?:[^\/\*])|(?:\/[^\*]))*\*\//m

      # so we go through removing them until there are no longer any matches.
      while regex.match(test_sql)
        test_sql = test_sql.split(regex).join(' ')
      end

      # now we can test for a number of missing items nice and easily.
      raise UnmatchedBracket,   'raw_sql contains an opening bracket with no closing bracket'     if test_sql.include?('[')
      raise UnmatchedBracket,   'raw_sql contains a closing bracket with no opening bracket'      if test_sql.include?(']')
      raise UnclosedQuote,      'raw_sql contains an unclosed string literal'                     if test_sql.include?("'")
      raise UnclosedQuote,      'raw_sql contains an unclosed ANSI quoted literal'                if test_sql.include?('"')
      raise UnmatchedComment,   'raw_sql contains a "/*" sequence with no matching "*/" sequence' if test_sql.include?('/*')
      raise UnmatchedComment,   'raw_sql contains a "*/" sequence with no matching "*/" sequence' if test_sql.include?('*/')

      # and finally we can test for extra DDL.
      # only the initial CREATE statement is allowed.
      regex = /\s(create|alter|drop|grant)\s/im
      if (match = regex.match(test_sql))
        raise ExtraDDL, "raw_sql contains a #{match[1]} statement after the initial CREATE statement"
      end

    end

    def to_create_sql
      "CREATE #{type} \"#{name}\"\n#{definition}"
    end

    def to_drop_sql
      "DROP #{type} \"#{name}\""
    end

    def to_s
      "#{type} #{name}"
    end

  end
end
