module BarkestCore
  ##
  # This class can be used to conditionally update a target SQL database with custom code.
  #
  # The updater will hunt through the SQL files found in the +sql_sources+ passed in.
  # For each source, the updater calculates the new version and compares it against the
  # existing version.  If the new version is actually newer, the updater will update the
  # object in the database.
  class MsSqlDbUpdater

    VERSION_TABLE_NAME = 'zz_barkest__versions'
    private_constant :VERSION_TABLE_NAME

    attr_reader :table_prefix

    def initialize(options = {})
      options = {
          table_name_prefix: 'zz_barkest_'
      }.merge(options || {}).symbolize_keys

      @table_prefix = options[:table_name_prefix].to_s
      valid_regex = /^[a-z][a-z0-9_]*$/im
      raise 'invalid table prefix' unless valid_regex.match(@table_prefix)

      @conn = Class.new(ActiveRecord::Base)
      @sources = [ ]
      @source_paths = [ ]

      # 'sql/barkest' relative to the running application.
      add_source_path 'sql/barkest'
    end

    def source_paths
      @source_paths.dup.freeze
    end

    def sources
      @sources.dup.freeze
    end

    def add_source(timestamp, sql)
      sql_def = BarkestCore::MsSqlDefinition.new(sql, '', timestamp)
      sql_def.instance_variable_set(:@source_location, "::#{sql_def.name}::")
      add_sql_def sql_def
      nil
    end

    def add_source_path(path)
      raise 'path must be a string' unless path.is_a?(String)

      path = File.expand_path(path)
      raise 'cannot add root path' if path == '/'
      path = path[0...-1] if path[-1] == '/'

      @source_paths << path unless @source_paths.include?(path)

      if Dir.exist?(path)
        Dir.glob("#{path}/*.rb").each do |source|
          add_sql_def BarkestCore::MsSqlDefinition.new(File.read(source), source, File.mtime(source))
        end
      end

      nil
    end

    def update_db(config, options = {})

      options ||= {}

      runtime_user = config[:username]

      @conn.remove_connection
      @conn.establish_connection config

      if have_db_control?
        warn "WARNING: Runtime user '#{runtime_user}' has full access to the database. (this is not recommended)"
      else
        raise 'please provide update_username and update_password for a user with full access to the database' unless config[:update_username]

        use_config = config.dup
        use_config[:username] = config[:update_username]
        use_config[:password] = config[:update_password]

        @conn.remove_connection
        @conn.establish_connection use_config

        raise 'provided update user does not have full access to the database' unless have_db_control?
      end

      unless @conn.object_exists?(VERSION_TABLE_NAME)
        debug 'Creating version tracking table...'
        db_connection.execute <<-EOSQL
CREATE TABLE [#{VERSION_TABLE_NAME}] (
  [object_name] VARCHAR(120) NOT NULL PRIMARY KEY,
  [object_type] VARCHAR(40) NOT NULL,
  [object_version] VARCHAR(40) NOT NULL,
  [created] DATETIME NOT NULL,
  [updated] DATETIME NOT NULL,
  [created_by] VARCHAR(120),
  [updated_by] VARCHAR(120)
)
        EOSQL
      end

      if (proc = (options[:before_update] || options[:pre_update]))
        if proc.respond_to?(:call)
          debug 'Running pre-update code...'
          proc.call db_connection, runtime_user
        end
      end

      debug 'Processing source list...'
      sources.each do |src|
        src.name_prefix = table_prefix

        cur_ver = get_version src.prefixed_name

        if cur_ver
          raise "object type mismatch for #{src.prefixed_name}" unless src.type.upcase == cur_ver['object_type'].upcase
          if cur_ver['object_version'].to_i >= src.version.to_i
            debug " > Preserving #{src.prefixed_name}..."
            next  # source
          else
            debug " > Updating #{src.prefixed_name}..."
            if src.command.upcase == 'CREATE'
              db_connection.execute src.drop_sql
            end
          end
        else
          debug " > Creating #{src.prefixed_name}..."
        end

        db_connection.execute src.update_sql
        db_connection.execute src.grant_sql

        src.name_prefix = ''
      end

      if (proc = (options[:after_update] || options[:post_update]))
        if proc.respond_to?(:call)
          debug 'Running post-update code...'
          proc.call db_connection, runtime_user
        end
      end

      yield db_connection, runtime_user if block_given?
    end

    private

    def get_version(object_name)
      object_name = object_name.to_s.gsub("'", "''")
      db_connection.exec_query("SELECT [object_name], [object_type], [object_version], [created], [updated], [created_by], [updated_by] FROM [#{VERSION_TABLE_NAME}] WHERE [object_name]='#{object_name}'").first
    end

    def set_version(object_name, object_type, object_version)
      raw_obj_name = object_name
      existing = get_version(raw_obj_name)

      object_name = object_name.to_s.gsub("'", "''")
      object_type = object_type.to_s.gsub("'", "''")
      object_version = object_version.to_s.gsub("'", "''")
      time = Time.now.strftime('%Y-%m-%d %H:%M:%S').gsub("'", "''")
      app = (Rails && Rails.application) ? Rails.application.class.to_s.gsub("'", "''") : '<UNKNOWN>'

      if existing
        raise 'object type mismatch' unless existing['object_type'] == object_type
        db_connection.execute "UPDATE [#{VERSION_TABLE_NAME}] SET [object_version]='#{object_version}', [updated]='#{time}', [updated_by]='#{app}' WHERE [object_name]='#{object_name}'"
      else
        db_connection.execute "INSERT INTO [#{VERSION_TABLE_NAME}] ([object_name], [object_type], [object_version], [created], [updated], [created_by], [updated_by]) VALUES ('#{object_name}','#{object_type}','#{object_version}','#{time}','#{time}','#{app}','#{app}')"
      end

      get_version raw_obj_name
    end

    def db_connection
      @conn.connection
    end

    def have_db_control?
      # user must have CONTROL permission on the database itself.
      # if it does, then we are good to move forward.
      result = db_connection.exec_query('SELECT COUNT(*) AS "one" FROM "fn_my_permissions"(NULL, \'DATABASE\') WHERE "permission_name"=\'CONTROL\'').first
      result && result['one'] == 1
    end

    def debug(s)
      if Rails && Rails.logger && Rails.logger.respond_to?(:debug)
        Rails.logger.debug(s)
      else
        $stdout.puts s
      end
    end

    def warn(s)
      if Rails && Rails.logger && Rails.logger.respond_to?(:warn)
        Rails.logger.warn(s)
      else
        $stderr.puts s
      end
    end

    def add_sql_def(sql_def)
      existing = @sources.find{ |item| item.name == sql_def.name }
      if existing
        if existing == sql_def
          debug "A #{existing.type.downcase} named #{existing.name} is already defined with the same source."
          return nil
        end
        if existing.type != sql_def.type
          raise "Cannot change type of object named #{existing.name} from #{existing.type} to #{sql_def.type}."
        end
        if existing.version.to_i > sql_def.version.to_i
          warn "A #{existing.type.downcase} named #{existing.name} is already defined with newer source."
          return nil
        end
        if sql_def.command == 'CREATE'
          warn "Removing old definition for #{existing.type.downcase} named #{existing.name}."
          @sources.delete existing
        end
      end
      @sources << sql_def
    end

  end
end