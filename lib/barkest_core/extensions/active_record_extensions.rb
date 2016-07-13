
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

  ##
  # Searches the database to determine if an object with the specified name exists.
  #
  def self.object_exists?(object_name)

    if connection.class.name == 'ActiveRecord::ConnectionAdapters::SQLServerAdapter'
      # use sysobjects table.
      sql = 'SELECT "id" FROM "sysobjects" WHERE "name"=?'
      result = connection.exec_query(sql, name).first
      return true if result && result['id']
    elsif connection.class.name == 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
      # use sqlite_master table.
      sql = 'SELECT COUNT(*) AS "one" FROM "sqlite_master" WHERE ("type"=\'table\' OR "type"=\'view\') AND ("name"=?)'
      result = connection.exec_query(sql, name).first
      return true if result && result['one']  == 1
    else
      %w(TABLE VIEW ROUTINE).each do |type|
        sql = "SELECT COUNT(*) AS \"one\" FROM INFORMATION_SCHEMA.#{type}S T WHERE T.#{type}_NAME=?"
        result = connection.exec_query(sql, name).first
        return true if result && result['one'] == 1
      end
    end

    false
  end

end