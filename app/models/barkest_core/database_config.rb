module BarkestCore

  ##
  # Defines a database configuration for a database other than the core database.
  #
  # The core database must be configurared in +database.yml+ since it defines the SystemConfig.
  #
  # Other databases (say for a 3rd party database) can easily be defined using SystemConfig
  # and this class.
  class DatabaseConfig
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :name, :adapter, :encoding, :reconnect, :database, :pool, :username, :password, :timeout, :host, :port
    attr_accessor :extra_1_name, :extra_1_label, :extra_1_type
    attr_accessor :extra_2_name, :extra_2_label, :extra_2_type
    attr_accessor :extra_3_name, :extra_3_label, :extra_3_type
    attr_accessor :extra_4_name, :extra_4_label, :extra_4_type
    attr_accessor :extra_5_name, :extra_5_label, :extra_5_type
    attr_writer :extra_1_value, :extra_2_value, :extra_3_value, :extra_4_value, :extra_5_value
    attr_accessor :update_username, :update_password

    VALID_ADAPTERS = %w(sqlite3 mysql2 postgresql sqlserver)

    validates :adapter, inclusion: { in: VALID_ADAPTERS }
    validates :name, presence: true, length: { maximum: 128 }
    validates :database, presence: true
    validates :pool, presence: true
    validates :timeout, presence: true

    EXTRA_REGEX = /^extra_(?<KEY>\d+)_(?<VAR>name|label|type|value)$/
    VALID_EXTRA_KEY = (1..5)
    private_constant :EXTRA_REGEX, :VALID_EXTRA_KEY

    ##
    # Initializes the configuration.
    #
    # Define the parameters as hash values.  A string without a key will be used to set the name.
    def initialize(*args)
      @extra = []
      args.each do |arg|
        if arg.is_a?(String)
          self.name = arg
        elsif arg.is_a?(Hash)
          arg.each do |k,v|
            if respond_to?(:"#{k}?")
              send :"#{k}=", ((v === true || v === '1') ? '1' : '0')
            elsif respond_to?(:"#{k}")
              send :"#{k}=", v.to_s
            elsif (extra = EXTRA_REGEX.match(k.to_s))
              key = extra['KEY'].to_i
              if VALID_EXTRA_KEY.include?(key)
                send :"extra_#{key}_#{extra['VAR']}=", v.to_s
              end
            end
          end
        end
      end
    end

    # :nodoc:
    def method_missing(m,*a,&b)
      m = m.to_s

      if (key = EXTRA_REGEX.match(m))
        if key['VAR'] == 'value'
          key = key['KEY'].to_i
          if VALID_EXTRA_KEY.includ?(key)
            ivar = :"@#{m}"
            val = instance_variable_defined?(ivar) ? instance_variable_get(ivar) : nil
            tp = send("extra_#{key}_type")
            if tp == 'boolean'
              val = ((val === true) || (val == '1')) ? '1' : '0'
            end
            return val
          end
        end
      end

      super m, *a, &b
    end

    ##
    # Is the database configured to reconnect?
    def reconnect?
      reconnect.to_s.to_i != 0
    end

    ##
    # Gets the name for an extra value.
    def extra_name(index)
      return nil if index < 1 || index > 5
      send "extra_#{index}_name"
    end

    ##
    # Gets the label for an extra value.
    def extra_label(index)
      return nil if index < 1 || index > 5
      txt = send("extra_#{index}_label")
      txt = extra_name(index).to_s.humanize.capitalize if txt.blank?
      txt
    end

    ##
    # Gets the type for an extra value.
    def extra_type(index)
      return nil if index < 1 || index > 5
      send "extra_#{index}_type"
    end

    ##
    # Gets the field type for an extra value.
    def extra_field_type(index)
      t = extra_type(index).to_s
      case t
        when 'password'
          'password'
        when 'integer', 'float'
          'number'
        when 'boolean'
          'checkbox'
        else
          if t.downcase.index('in:')
            'select'
          else
            'text'
          end
      end
    end

    ##
    # Gets the options for a select field.
    def extra_field_options(index)
      if extra_field_type(index) == 'select'
        eval extra_type(index).partition(':')[2]
      else
        nil
      end
    end

    ##
    # Gets an extra value.
    def extra_value(index, convert = false)
      return nil if index < 1 || index > 5
      val = send "extra_#{index}_value"
      if convert
        case extra_type(index)
          when 'boolean'
            BarkestCore::BooleanParser.parse_for_boolean_column(val)
          when 'integer'
            BarkestCore::NumberParser.parse_for_int_column(val)
          when 'float'
            BarkestCore::NumberParser.parse_for_float_column(val)
          else
            val.to_s
        end
      end
    end


    ##
    # Converts this configuration into a hash.
    def to_h(convert_extra = true)
      ret = {
          adapter: adapter.to_s,
          database: database.to_s,
          pool: pool.to_s.to_i,
          timeout: timeout.to_s.to_i,
          reconnect: reconnect?,
          encoding: encoding ? encoding.to_s : nil,
          host: host.blank? ? nil : host.to_s,
          port: port.blank? ? nil : port.to_s.to_i,
          username: username.blank? ? nil : username.to_s,
          password: password.blank? ? nil : password.to_s,
          update_username: update_username.blank? ? nil : update_username.to_s,
          update_password: update_password.blank? ? nil : update_password.to_s,
      }
      VALID_EXTRA_KEY.each do |idx|
        if convert_extra
          unless extra_name(idx).blank?
            ret[extra_name(idx).to_sym] = extra_value(idx, true)
          end
        else
          ret[:"extra_#{idx}_name"] = send(:"extra_#{idx}_name")
          ret[:"extra_#{idx}_label"] = send(:"extra_#{idx}_label")
          ret[:"extra_#{idx}_type"] = send(:"extra_#{idx}_type")
          ret[:"extra_#{idx}_value"] = send(:"extra_#{idx}_value")
        end
      end
      ret
    end

    ##
    # Saves this configuration (encrypted) to SystemConfig.
    def save
      SystemConfig.set name, to_h(false), true
    end

    ##
    # Loads the configuration for the specified database from SystemConfig.
    def DatabaseConfig.load(name)
      DatabaseConfig.new(name, SystemConfig.get(name))
    end

    ##
    # Gets a list of the registered databases for enumeration.
    def DatabaseConfig.registered
      @registered ||= []
    end

    ##
    # Registers a database for enumeration.
    def DatabaseConfig.register(db_id)
      db_id = db_id.to_s.downcase
      unless db_id.blank?
        registered << db_id unless registered.include?(db_id)
      end
      nil
    end

  end
end