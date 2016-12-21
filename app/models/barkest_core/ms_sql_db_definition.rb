module BarkestCore
  ##
  # This class can be used to conditionally update a target SQL database with custom code.
  #
  # The updater will hunt through the SQL files found in the +sql_sources+ passed in.
  # For each source, the updater calculates the new version and compares it against the
  # existing version.  If the new version is actually newer, the updater will update the
  # object in the database.
  class MsSqlDbDefinition

    ##
    # The base error for errors raised by the updater class.
    UpdateError = Class.new(StandardError)

    ##
    # The error raised when the provided connection does not provide a user with full control over the database.
    NeedFullAccess = Class.new(UpdateError)

    ##
    # The error raised when an object type doesn't match the previous type for the object with the specified name.
    ObjectTypeMismatch = Class.new(UpdateError)

    ##
    # The name of the table holding the object versions.
    VERSION_TABLE_NAME = 'zz_barkest__versions'


    attr_reader :table_prefix

    class Conn < ActiveRecord::Base
      self.abstract_class = true
    end

    ##
    # Defines a new updater.
    #
    # Options can include +source_paths+, +before_update+, and +after_update+.
    #
    # The +before_update+ and +after_update+ options define a callback to be run before or after
    # the database update is performed.  This can be a string referencing a method or it can be a Proc.
    #
    #   MsSqlDbDefinition.new(
    #     :before_update => 'MyClass.my_method(db_conn,user)',
    #     :after_update => Proc.new do |db_conn, user|
    #                        ...
    #                      end
    #   )
    #
    # If you use the string option, note that the +db_conn+ and +user+ variables are available.  In the example
    # above they are being passed to the method as arguments.
    def initialize(options = {})
      options = {
          table_name_prefix: 'zz_barkest_'
      }.merge(options || {}).symbolize_keys

      @table_prefix = options[:table_name_prefix].to_s
      valid_regex = /^[a-z][a-z0-9_]*$/im
      raise 'invalid table prefix' unless valid_regex.match(@table_prefix)

      @sources = [ ]
      @source_paths = [ ]
      @pre_update = options.delete(:before_update) || options.delete(:pre_update)
      @post_update = options.delete(:after_update) || options.delete(:post_update)

      # and any other paths provided via options.
      if options[:source_paths]
        if options[:source_paths].is_a?(String)
          add_source_path options[:source_paths]
        elsif options[:source_paths].respond_to?(:each)
          options[:source_paths].each do |path|
            add_source_path path.to_s
          end
        else
          add_source_path options[:source_paths].to_s
        end
      end

    end

    ##
    # Gets an object's name according to this DB updater.
    def object_name(unprefixed_name)
      name = unprefixed_name.to_s
      return name if name.index(table_prefix) == 0
      "#{table_prefix}#{name}"
    end

    ##
    # Gets all of the source paths that have currently been searched.
    def source_paths
      @source_paths.dup.freeze
    end

    ##
    # Gets all of the sources currently loaded.
    def sources
      @sources.dup.map{|t| t.name_prefix = table_prefix; t}.freeze
    end

    ##
    # Adds a source using a specific timestamp.
    #
    # The first line of the SQL should be a comment specifying the timestamp for the source.
    #   -- 2016-12-19 15:45
    #   -- 2016-12-19
    #   -- 201612191545
    #   -- 20161219
    #
    # The timestamp will be converted into a 12-digit number, if time is not specified it will be right-padded
    # with zeroes to get to the 12-digit number.
    #
    # The +sql+ should be a valid create/alter table/view/function statement.
    def add_source(sql)
      sql_def = BarkestCore::MsSqlDefinition.new(sql, '')
      sql_def.instance_variable_set(:@source_location, "::#{sql_def.name}::")
      add_sql_def sql_def
      nil
    end

    ##
    # Adds a MsSqlDefinition object to the sources for this updater.
    #
    # The +definition+ should be a previously created MsSqlDefinition object.
    def add_source_definition(definition)
      add_sql_def definition
      nil
    end

    ##
    # Adds all SQL files found in the specified directory to the sources for this updater.
    #
    # The +path+ should contain the SQL files.  If there are subdirectories, you should
    # include them individually.
    #
    # The source files should specify a timestamp in the first comment.
    #   -- 2016-12-19 15:45
    #   -- 2016-12-19
    #   -- 201612191545
    #   -- 20161219
    #
    # The timestamp will be converted into a 12-digit number, if time is not specified it will be right-padded
    # with zeroes to get to the 12-digit number.
    #
    def add_source_path(path)
      raise 'path must be a string' unless path.is_a?(String)

      path = File.expand_path(path)
      raise 'cannot add root path' if path == '/'
      path = path[0...-1] if path[-1] == '/'

      unless @source_paths.include?(path)
        @source_paths << path

        if Dir.exist?(path)
          Dir.glob("#{path}/*.sql").each do |source|
            add_sql_def BarkestCore::MsSqlDefinition.new(File.read(source), source, File.mtime(source))
          end
        end
      end

      nil
    end

    ##
    # Performs the database update using the specified configuration.
    #
    # A warning will be logged if the runtime user has full access to the database.
    #
    # An error will be raised if there is the runtime user does not have full access and no update_user is provided,
    # or if an update_user is provided who also does not have full access to the database.
    def update_db(config, options = {})

      begin
        options ||= {}

        runtime_user = config[:username]

        Conn.remove_connection
        Conn.establish_connection config

        if have_db_control?
          warn "WARNING: Runtime user '#{runtime_user}' has full access to the database. (this is not recommended)" unless Rails.env.test?
        else
          raise NeedFullAccess, 'please provide update_username and update_password for a user with full access to the database' unless config[:update_username]

          use_config = config.dup
          use_config[:username] = config[:update_username]
          use_config[:password] = config[:update_password]

          Conn.remove_connection
          Conn.establish_connection use_config

          raise NeedFullAccess, 'provided update user does not have full access to the database' unless have_db_control?
        end

        unless Conn.object_exists?(VERSION_TABLE_NAME)
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

        if (proc = (options[:before_update] || options[:pre_update] || @pre_update))
          if proc.is_a?(String)
            code = proc
            proc = Proc.new { |db_conn, user| eval code }
          end
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
            raise ObjectTypeMismatch, "object type mismatch for #{src.prefixed_name}" unless src.type.upcase == cur_ver['object_type'].upcase
            if cur_ver['object_version'].to_i >= src.version.to_i
              debug " > Preserving #{src.prefixed_name}..."
              next  # source
            else
              debug " > Updating #{src.prefixed_name}..."
              if src.is_create?
                db_connection.execute src.drop_sql
              end
            end
          else
            debug " > Creating #{src.prefixed_name}..."
          end

          db_connection.execute src.update_sql
          db_connection.execute src.grant_sql(runtime_user)
          set_version src.prefixed_name, src.type, src.version

          src.name_prefix = ''
        end

        if (proc = (options[:after_update] || options[:post_update] || @post_update))
          if proc.is_a?(String)
            code = proc
            proc = Proc.new { |db_conn, user| eval code }
          end
          if proc.respond_to?(:call)
            debug 'Running post-update code...'
            proc.call db_connection, runtime_user
          end
        end

        yield db_connection, runtime_user if block_given?

      ensure
        Conn.remove_connection
      end

      true
    end

    ##
    # Registers a DB updater and tells BarkestCore that the named database exists and could use a configuration.
    #
    # The +options+ will be passed to the MsSqlDbDefinition constructor, except for the +extra_params+ key.
    # If this key is provided, it is pulled out and used for the defaults for the database configuration.
    #
    # Ideally this is to provide the +extra_[1|2]_name+, +extra_[1|2]_type+, and +extra_[1|2]_value+ parameters, but
    # you can also use it to provide reasonable defaults for +host+, +database+, or even credentials.
    #
    def self.register(name, options={})
      name = symbolize_name name

      raise 'already registered' if registered.include?(name)

      options = (options || {}).symbolize_keys

      extra_params = options.delete(:extra_params)
      if extra_params.is_a?(Hash)
        repeat = true
        while repeat
          repeat = false
          extra_params.dup.each do |k,v|
            if v.is_a?(Hash)
              extra_params.delete(k)
              v.each do |subk,subv|
                extra_params[:"#{k}_#{subk}"] = subv
              end
              repeat = true
            end
          end
        end
      end

      options[:table_name_prefix] ||=
          if name.to_s.index('barkest') == 0
            "zz_#{name}_"
          else
            "zz_barkest_#{name}_"
          end

      updater = MsSqlDbDefinition.new(options)

      registered[name] = updater

      # Register with DatabaseConfig to enable the config page for this DB.
      DatabaseConfig.register name

      cfg_def = (extra_params.is_a?(Hash) ? extra_params : {})
                    .merge(
                        {
                            adapter: 'sqlserver',
                            pool: 5,
                            timeout: 30000,
                            port: 1433,
                        }
                    )

      # Register with BarkestCore so that the default configuration is somewhat appropriate.
      BarkestCore.register_db_config_defaults name, cfg_def

      updater
    end

    ##
    # Gets a DB updater by name.
    def self.[](name)
      name = symbolize_name name
      registered[name]
    end

    ##
    # Gets a list of all the DB updaters currently registered.
    def self.keys
      registered.keys
    end

    ##
    # Iterates through the registered DB updaters.
    #
    # Yields the db_name and the db_updater to the block.
    def self.each
      registered.each do |k,v|
        yield k, v if block_given?
      end
    end

    private

    def self.symbolize_name(name)
      name.to_s.underscore.gsub('/', '_').to_sym
    end

    def self.registered
      @registered ||= {}
    end

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
        raise ObjectTypeMismatch, 'object type mismatch' unless existing['object_type'] == object_type
        db_connection.execute "UPDATE [#{VERSION_TABLE_NAME}] SET [object_version]='#{object_version}', [updated]='#{time}', [updated_by]='#{app}' WHERE [object_name]='#{object_name}'"
      else
        db_connection.execute "INSERT INTO [#{VERSION_TABLE_NAME}] ([object_name], [object_type], [object_version], [created], [updated], [created_by], [updated_by]) VALUES ('#{object_name}','#{object_type}','#{object_version}','#{time}','#{time}','#{app}','#{app}')"
      end

      get_version raw_obj_name
    end

    def db_connection
      Conn.connection
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
          raise ObjectTypeMismatch, "Cannot change type of object named #{existing.name} from #{existing.type} to #{sql_def.type}."
        end
        if existing.version.to_i > sql_def.version.to_i
          warn "A #{existing.type.downcase} named #{existing.name} is already defined with newer source."
          return nil
        end
        if sql_def.is_create?
          warn "Removing old definition for #{existing.type.downcase} named #{existing.name}."
          @sources.delete existing
        end
      end
      @sources << sql_def
    end

  end
end