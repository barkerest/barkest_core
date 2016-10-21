require 'zlib'

module BarkestCore

  ##
  # Contains a SQL definition to create a single table, view, function, or procedure.
  #
  # SQL source is not validated, however simple checks are made to ensure that only
  # one DDL statement is present unless you are creating a procedure in which case this
  # check is skipped.
  #
  # Function return types are grabbed as well so you know if your function is returning
  # a table or an integral type.
  class MsSqlDefinition
    InvalidDefinition       = Class.new(StandardError)

    EmptyDefinition         = Class.new(InvalidDefinition)
    MissingCreateStatement  = Class.new(InvalidDefinition)
    ExtraDDL                = Class.new(InvalidDefinition)
    UnmatchedBracket        = Class.new(InvalidDefinition)
    UnclosedQuote           = Class.new(InvalidDefinition)
    UnmatchedComment        = Class.new(InvalidDefinition)
    MissingReturnType       = Class.new(InvalidDefinition)

    attr_accessor :name_prefix

    attr_reader :command, :name, :type, :definition, :version, :return_type, :source_location

    def initialize(raw_sql, source = '', timestamp = 0)

      @source_location = source.to_s
      @return_type = :table  # the default.  functions can be different.  procedures can be iffy since they may or may not return a result set.
      @command = 'CREATE'

      if timestamp.is_a?(String)
        timestamp = Time.new(timestamp)
      end

      if timestamp.is_a?(Date)
        timestamp = "#{timestamp.year.to_s.rjust(4,'0')}#{timestamp.month.to_s.rjust(2,'0')}#{timestamp.day.to_s.rjust(2,'0')}0000".to_i
      elsif timestamp.is_a?(Time)
        timestamp = "#{timestamp.year.to_s.rjust(4,'0')}#{timestamp.month.to_s.rjust(2,'0')}#{timestamp.day.to_s.rjust(2,'0')}#{timestamp.hour.to_s.rjust(2,'0')}#{timestamp.min.to_s.rjust(2,'0')}".to_i
      end

      timestamp = 0 unless timestamp.is_a?(Fixnum)

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
      # or ALTER TABLE "XYZ"
      regex = /^(?:(?<CMD>ALTER)\s+(?<TYPE>TABLE)|(?<CMD>CREATE)\s+(?<TYPE>TABLE|VIEW|FUNCTION|PROCEDURE))\s+["\[]?(?<NAME>[A-Z][A-Z0-9_]*)["\]]?\s+(?<DEFINITION>.*)$/im
      match = regex.match(raw_sql)

      raise MissingCreateStatement, 'raw_sql must contain a "CREATE|ALTER VIEW|FUNCTION|PROCEDURE" statement' unless match

      @command = match['CMD'].upcase
      @type = match['TYPE'].upcase
      @name = match['NAME']
      @definition = match['DEFINITION'].strip

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
      raise UnmatchedComment,   'raw_sql contains a "*/" sequence with no matching "/*" sequence' if test_sql.include?('*/')

      unless type == 'PROCEDURE'
        # and finally we can test for extra DDL.
        # only the initial CREATE statement is allowed.
        regex = /\s(create|alter|drop|grant)\s/im
        if (match = regex.match(test_sql))
          raise ExtraDDL, "raw_sql contains a #{match[1]} statement after the initial CREATE statement"
        end
      end

      # and for functions, get the return type.
      if type == 'FUNCTION'
        regex = /\sRETURNS\s+(?:@[A-Z][A-Z0-9_]*\s+)?(?<TYPE>[A-Z][A-Z0-9_()]*)\s/im

        match = regex.match(@definition)
        raise MissingReturnType, 'raw_sql seems to be missing the RETURNS statement for the function.' unless match

        rtype = match['TYPE'].downcase
        rsize = 0
        if rtype.include('(')
          rtype,_,rsize = rtype.partition('(')
          rsize = rsize.partition(')')[0].to_i
        end

        @return_type =
            case rtype
              when 'bit'
                :boolean

              when 'int', 'integer', 'bigint', 'smallint', 'tinyint'
                :integer

              when 'decimal', 'numeric', 'money', 'smallmoney'
                :decimal

              when 'float', 'real'
                :float

              when 'date', 'datetime', 'datetime2', 'time', 'smalldatetime', 'datetimeoffset'
                :time

              when 'char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext', 'binary', 'varbinary', 'image'
                :string

              else
                rtype.to_sym
            end
      end

      # set the version.
      @version = timestamp.to_s.ljust(12, '0') + Zlib.crc32(@definition).to_s(16).ljust(8,'0').upcase
    end

    def prefixed_name
      prefix = name_prefix.to_s
      return name if prefix == ''
      return name if name.index(prefix) == 0
      prefix + name
    end

    def update_sql
      "#{command} #{type} \"#{prefixed_name}\"\n#{definition}"
    end

    def drop_sql
      "DROP #{type} \"#{prefixed_name}\""
    end

    def grant_sql(user_name)
      sel_exec = if type == 'PROCEDURE'
                   'EXECUTE'
                 elsif type == 'FUNCTION' && return_type != :table
                   'EXECUTE'
                 elsif type == 'TABLE'
                   'SELECT, INSERT, UPDATE, DELETE'
                 else
                   'SELECT'
                 end

      "GRANT VIEW DEFINITION,#{sel_exec} ON \"#{prefixed_name}\" TO \"#{user_name}\""
    end

    def to_s
      "#{type} #{name}"
    end

    def ==(other)
      return false unless other.is_a?(MsSqlDefinition)
      return false unless other.name == name
      return false unless other.type == type
      return false unless other.definition == definition
      true
    end

  end
end
