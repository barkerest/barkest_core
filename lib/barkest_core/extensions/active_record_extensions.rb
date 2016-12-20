

module BarkestCore

  ##
  # Adds some helper methods to connection adapters.
  module ConnectionAdapterExtensions

    ##
    # Searches the database to determine if an object with the specified name exists.
    def object_exists?(object_name)
      safe_name = "'#{object_name.gsub('\'','\'\'')}'"
      klass = self.class.name

      sql =
          if klass == 'ActiveRecord::ConnectionAdapters::SQLServerAdapter'
            # use sysobjects table.
            "SELECT COUNT(*) AS \"one\" FROM \"sysobjects\" WHERE \"name\"=#{safe_name}"
          elsif klass == 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
            # use sqlite_master table.
            "SELECT COUNT(*) AS \"one\" FROM \"sqlite_master\" WHERE (\"type\"='table' OR \"type\"='view') AND (\"name\"=#{safe_name})"
          else
            # query the information_schema TABLES and ROUTINES views.
            "SELECT SUM(Z.\"one\") AS \"one\" FROM (SELECT COUNT(*) AS \"one\" FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME=#{safe_name} UNION SELECT COUNT(*) AS \"one\" FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME=#{safe_name}) AS Z"
          end

      result = exec_query(sql).first

      result && result['one'] >= 1
    end

    ##
    # Executes a stored procedure.
    #
    # For MS SQL Server, this will return the return value from the procedure.
    # For other providers, this is the same as +execute+.
    def exec_sp(stmt)
      klass = self.class.name
      if klass == 'ActiveRecord::ConnectionAdapters::SQLServerAdapter'
        rex = /^exec(?:ute)?\s+[\["]?(?<PROC>[a-z][a-z0-9_]*)[\]"]?(?<ARGS>\s.*)?$/i
        match = rex.match(stmt)
        if match
          exec_query("DECLARE @RET INTEGER; EXECUTE @RET=[#{match['PROC']}]#{match['ARGS']}; SELECT @RET AS [RET]").first['RET']
        else
          execute stmt
        end
      else
        execute stmt
      end
    end

  end
end


## Add a few extensions to models.
ActiveRecord::Base.class_eval do

  ##
  # Tests for equality on ID.
  def ==(other)
    if respond_to?(:id)
      if other.is_a?(Numeric)
        id == other
      elsif other.class == self.class
        id == other.id
      else
        false
      end
    else
      self.inspect == other.inspect
    end
  end

  ##
  # Loads the concerns for the current model.
  def self.add_concerns(subdir = nil)
    klass = self
    subdir ||= klass.name.underscore

    Dir.glob(File.expand_path("../../../app/models/concerns/#{subdir}/*.rb", __FILE__)).each do |item|
      require item
      mod_name = File.basename(item)[0...-3].camelcase
      if const_defined? mod_name
        mod_name = const_get mod_name
        klass.include mod_name
      else
        raise StandardError.new("The #{mod_name} module does not appear to be defined.")
      end
    end
  end

  # patch 'connection'  so that we can insert our extensions to the returned adapters.
  class << self
    # :nodoc:
    alias_method :barkest_core_original_connection, :connection
  end

  # :nodoc:
  def self.connection(*args)
    ret = barkest_core_original_connection(*args)
    unless ret.class.include?(BarkestCore::ConnectionAdapterExtensions)
      ret.class.include BarkestCore::ConnectionAdapterExtensions
    end
    yield ret if block_given?
    ret
  end

  ##
  # Searches the database to determine if an object with the specified name exists.
  #
  # This method is actually attached to the connection adapter, so anywhere you have the +connection+ you can use it
  # to query if an object exists.
  def self.object_exists?(object_name)
    return connection.object_exists?(object_name)
  end

end


