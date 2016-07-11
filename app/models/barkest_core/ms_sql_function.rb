module BarkestCore

  ##
  # This class provides a model-like interface to SQL Server User Defined Functions.
  #
  # It's understandable that in terms of separation of concerns, logic has no place in the database.
  # In the SQL Server world, UDFs cannot make changes to data, they can only present it.
  # With that in mind, I consider UDFs to be parameterized queries, that are often times orders of magnitude
  # faster than trying to construct a query via ActiveRecord.
  #
  # Although "models" inheriting from this class are not ActiveRecord models, this class does include
  # ActiveModel::Model and ActiveModel::Validations to allow you to construct your UDF models with similar attributes
  # to ActiveRecord models.  For instance, you can ensure that returned values meet certain requirements using the
  # validations.  This allows you to further remove logic from the database and still gain the benefit of running
  # a parameterized query.
  class MsSqlFunction

    include ActiveModel::Model
    include ActiveModel::Validations

    include DateParser
    include NumberParser
    include BooleanParser

    ##
    # Sets the connection handler to use for this function.
    #
    # The default behavior is to piggyback on the ActiveRecord::Base connections.
    # To override this behavior, provide a class that responds to the :connection method.
    #
    #   class MyFunction < MsSqlFunction
    #     use_connection SomeMsSqlTable
    #   end
    #
    def self.use_connection(connected_object)
      @conn_handler =
          if connected_object.is_a?(Class)
            connected_object
          else
            const_get(connected_object || 'ActiveRecord::Base')
          end
      raise ArgumentError.new('Connected object must respond to :connection') unless @conn_handler.respond_to?(:connection)
    end

    ##
    # Gets a connection from the connection handler.
    #
    # The connection must be to a SQL Server since this class has no idea how to work with UDFs in any other language at this time.
    #
    def self.connection
      conn = connection_handler.connection
      raise StandardError.new('The connection must be to a SQL server.') unless conn.is_a?(ActiveRecord::ConnectionAdapters::SQLServerAdapter)
      conn
    end

    ##
    # Gets the UDF name for this class.
    #
    # It is important that you do not set this on the MsSqlFunction class itself.
    #
    def self.function_name
      @udf
    end

    ##
    # Sets the UDF name for this class.
    #
    # It is important that you do not set this on the MsSqlFunction class itself.
    #
    def self.function_name=(value)
      raise StandardError.new("Function name for #{self} cannot be set.") if self == MsSqlFunction
      raise StandardError.new("Function name for #{self} cannot be set more than once.") unless @udf.blank?
      @udf = process_udf(value)
    end

    ##
    # Returns parameter information for the UDF.
    #
    # The returned hash contains the most important attributes for most applications including :type, :data_type, and :default.
    #
    def self.parameters
      @param_info.inject({}) { |memo,(k,v)| memo[k] = { type: v[:type], data_type: v[:data_type], default: v[:default] }; memo }
    end

    ##
    # Sets the default values for parameters.
    #
    # The +values+ should be a hash using the parameter name as the key and the default as the value.
    # The easiest way to ensure it works is to set the defaults in the hash returned from #parameters.
    #
    def self.parameters=(values)
      if values && values.is_a?(Hash)
        values.each do |k,v|
          if @param_info[k]
            if v.is_a?(Hash)
              @param_info[k][:default] = v[:default]
            else
              @param_info[k][:default] = v
            end
          end
        end
      end
    end

    ##
    # Gets the column information for the UDF.
    def self.columns
      @column_info
    end

    ##
    # Selects the data from the UDF using the provided parameters.
    #
    #   MyFunction.select(user: 'john', day_of_week: 3)
    #
    # Returns an array containing the rows returned.
    #
    def self.select(params = {})

      args = []

      params = {} unless params.is_a?(Hash)

      @param_info.each do |k,v|
        args[v[:ordinal]] = [ v[:data_type], self.send(v[:format], params[k] || v[:default]) ]
      end

      where = ''
      idx = args.count
      params.each do |k,v|
        unless @param_info.include? k
          where += ' AND ' unless where.blank?
          where += "([#{k}]"
          if v.is_a? Array
            # IN clause
            where += ' IN (' + v.map{ |value| quote_param(value)[0] }.join(', ') + ')'
          elsif v.is_a? Hash
            if v.include? :between
              v = v[:between]
              raise ArgumentError.new("between clause for #{k} requires an array argument") unless v.is_a? Array
              where += " BETWEEN @#{idx} AND @#{idx + 1}"
              value,type = quote_param(v[0])
              args[idx] = [ type, value ]
              value,type = quote_param(v[1])
              args[idx + 1] = [ type, value ]
              idx += 2
            elsif v.include? :like
              where += " LIKE @#{idx}"
              value,type  = quote_param(v[:like].to_s)
              args[idx] = [ type, value ]
              idx += 1
            else
              operator = nil
              value = nil
              { not: '<>', lt: '<', lte: '<=', gt: '>', gte: '>=', eq: '=' }.each do |key,op|
                if v.include? key
                  operator = op
                  value = v[key]
                  break
                end
              end
              raise ArgumentError.new("unknown clause for #{k}") unless operator
              where += " #{operator} @#{idx}"
              value,type = quote_param(value)
              args[idx] = [ type, value ]
              idx += 1
            end
          else
            where += " = @#{idx}"
            value,type = quote_param(v)
            args[idx] = [ type, value ]
            idx += 1
          end
          where += ')'
        end
      end

      sql = "SELECT * FROM #{@udf}(#{@udf_args})"
      sql += " WHERE #{where}" unless where.blank?

      ret = []

      execute(sql, args) do |row|
        ret << self.new(row)
      end

      ret
    end


    private

    def self.quote_param(value)
      if value.nil?
        [ 'NULL', 'varchar(1)' ]
      elsif value.is_a? Integer
        [ value.to_s, 'integer' ]
      elsif value.is_a? Float
        [ value.to_s, 'float' ]
      elsif value.is_a?(Date) || value.is_a?(Time)
        [ value.strftime('%Y-%m-%d %H:%M:%S'), 'datetime' ]
      elsif value.is_a? TrueClass
        [ 1, 'bit' ]
      elsif value.is_a? FalseClass
        [ 0, 'bit' ]
      else
        [ "'#{value.to_s.gsub('\'','\'\'')}'", 'varchar(max)' ]
      end
    end

    def self.instrumenter
      @instrumenter ||= ActiveSupport::Notifications.instrumenter
    end


    def self.execute(sql, binds)
      sql = "EXEC sp_executesql N'#{sql.gsub('\'','\'\'')}'"

      unless binds.blank?
        binds.each_with_index do |v,i|
          sql += i == 0 ? ', N\'' : ', '
          sql += "@#{i} #{v[0]}"
        end
        sql += '\''
        binds.each_with_index do |v,i|
          sql += ", @#{i}=#{v[1]}"
        end
      end

      ret = []

      conn = connection
      instrumenter.instrument(
          "sql.active_record",
          :sql            => sql,
          :name           => 'SQL',
          :connection_id  => conn.object_id,
          :statement_name => nil,
          :binds          => nil) do
        conn.instance_variable_get("@connection").execute(sql).each(as: :hash) do |row|
          ret << row
          yield row if block_given?
        end
      end

      ret
    end


    def self.parse_for_string_filter(value)
      value.nil? ? 'NULL' : "'#{value.to_s.gsub('\'','\'\'')}'"
    end

    def self.connection_handler
      @conn_handler ||= const_get('ActiveRecord::Base')
    end

    def self.get_udf_definition(name)
      execute('SELECT R.ROUTINE_CATALOG AS [catalog], R.ROUTINE_SCHEMA AS [schema], R.ROUTINE_NAME AS [name], ' +
                                'R.ROUTINE_DEFINITION AS [definition] FROM INFORMATION_SCHEMA.ROUTINES R WHERE ' +
                                'R.ROUTINE_TYPE=\'FUNCTION\' AND R.DATA_TYPE=\'TABLE\' AND R.ROUTINE_NAME=@0',
              [
                  ['varchar(100)', parse_for_string_filter(name)]
              ]
      ) do |row|
        return [ row['catalog'], row['schema'], row['name'], row['definition'] ]
      end
      [ nil, nil, nil, nil ]
    end


    def self.get_udf_params(sql_def)
      # get everything before the return definition
      # should be something like "CREATE FUNCTION xyz (a type, b type)"
      sql_def = sql_def.split(/\sreturn/i)[0]

      ret = {}

      if sql_def['(']
        param_defs = sql_def.split('(', 2)[1].rpartition(')')[0].split(',').map{|d| d.strip}

        param_defs.each_with_index do |raw,idx|
          pname,pdatatype = raw.split(' ')

          psym = pname
          if psym[0] == '@'
            psym = psym[1..-1]
          end
          psym = psym.underscore.to_sym

          pdatatype.downcase!

          if pdatatype.include? 'date'
            pfmt = :parse_for_date_filter
            ptype = :datetime
          elsif pdatatype.include? 'float'
            pfmt = :parse_for_float_filter
            ptype = :float
          elsif pdatatype.include? 'int'
            pfmt = :parse_for_int_filter
            ptype = :integer
          elsif pdatatype.include? 'bit'
            pfmt = :parse_for_boolean_filter
            ptype = :boolean
          else
            pfmt = :parse_for_string_filter
            ptype = :string
          end

          ret[psym] = { name: pname, data_type: pdatatype, type: ptype, format: pfmt, ordinal: idx }
        end
      end

      ret
    end


    def self.get_udf_columns(catalog, schema, name)
      execute('SELECT C.COLUMN_NAME AS [name], C.IS_NULLABLE AS [nullable], C.DATA_TYPE AS [type], ' +
                                'C.CHARACTER_MAXIMUM_LENGTH AS [length], C.ORDINAL_POSITION AS [ordinal] ' +
                                'FROM INFORMATION_SCHEMA.ROUTINE_COLUMNS C ' +
                                'WHERE C.TABLE_CATALOG=@0 AND C.TABLE_SCHEMA=@1 AND C.TABLE_NAME=@2 ' +
                                'ORDER BY C.ORDINAL_POSITION',
              [
                  ['varchar(100)', parse_for_string_filter(catalog)],
                  ['varchar(100)', parse_for_string_filter(schema)],
                  ['varchar(100)', parse_for_string_filter(name)]
              ]
      ) do |row|
        yield row if block_given?
      end
    end


    def self.process_udf(name)
      catalog, schema, name, sql_def = get_udf_definition(name)

      raise StandardError.new("The specified function '#{name.to_s.gsub('\'','\'\'')}' could not be defined.") if sql_def.blank?

      @param_info = get_udf_params(sql_def)

      if @param_info.blank?
        @udf_args = ''
      else
        @udf_args = @param_info.map.with_index { |v,i| "@#{i}" }.join(', ')
      end

      @column_info = [ ]

      get_udf_columns(catalog, schema, name) do |column|
        col_key = column['name'].underscore.to_sym
        getter = col_key
        setter = "#{col_key}="

        col_info = { name: column['name'], key: col_key, ordinal: column['ordinal'], nullable: true, length: -1 }

        type = column['type'].downcase

        unless column['length'].blank?
          type += "(#{column['length']})"
          col_info[:length] = column['length'].to_i
        end

        col_info[:data_type] = type

        attr_accessor col_key

        if type == 'int' || type == 'integer'
          define_method setter do |value|
            instance_variable_set "@#{col_key}", self.class.parse_for_int_column(value)
          end
          col_info[:type] = :integer
        elsif type == 'float'
          define_method setter do |value|
            instance_variable_set "@#{col_key}", self.class.parse_for_float_column(value)
          end
          col_info[:type] = :float
        elsif type == 'date' || (type == 'datetime' && col_key.to_s.include?('date'))
          define_method setter do |value|
            instance_variable_set "@#{col_key}", self.class.parse_for_date_column(value)
          end
          col_info[:type] = :datetime
        elsif type == 'datetime'
          define_method setter do |value|
            instance_variable_set "@#{col_key}", self.class.parse_for_time_column(value)
          end
          col_info[:type] = :datetime
        elsif type == 'bit'
          define_method setter do |value|
            instance_variable_set "@#{col_key}", self.class.parse_for_boolean_column(value)
          end
          define_method "#{getter}?" do
            instance_variable_get "@#{col_key}"
          end
          col_info[:type] = :boolean
        else
          define_method setter do |value|
            instance_variable_set "@#{col_key}", value.nil? ? nil : value.to_s
          end
          col_info[:type] = :string
        end

        if column['nullable'].upcase == 'NO'
          validates col_key, presence: true
          col_info[:nullable] = false
        end

        @column_info << col_info
      end

      "[#{schema}].[#{name}]"
    end

  end
end
