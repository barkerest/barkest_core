module BarkestCore
  class DatabaseConfig
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :name, :adapter, :encoding, :reconnect, :database, :pool, :username, :password, :timeout, :host, :port
    attr_accessor :extra_1_name, :extra_1_type, :extra_1_value, :extra_2_name, :extra_2_type, :extra_2_value

    VALID_ADAPTERS = %w(sqlite3 mysql2 postgresql sqlserver)

    validates :adapter, inclusion: { in: VALID_ADAPTERS }
    validates :name, presence: true, length: { maximum: 128 }
    validates :database, presence: true
    validates :pool, presence: true
    validates :timeout, presence: true

    def initialize(*args)
      args.each do |arg|
        if arg.is_a?(String)
          self.name = arg
        elsif arg.is_a?(Hash)
          arg.each do |k,v|
            if respond_to?(:"#{k}?")
              send :"#{k}=", ((v === true || v === '1') ? '1' : '0')
            elsif respond_to?(:"#{k}")
              send :"#{k}=", v.to_s
            elsif extra_1_name.nil?
              self.extra_1_name = k.to_s
              self.extra_1_type =
                  if k.is_a?(TrueClass) || k.is_a?(FalseClass)
                    'bool'
                  elsif k.is_a?(Fixnum)
                    'int'
                  elsif k.is_a?(Float)
                    'float'
                  else
                    'string'
                  end
              self.extra_1_value = v.to_s
            elsif extra_2_name.nil?
              self.extra_2_name = k.to_s
              self.extra_2_type =
                  if k.is_a?(TrueClass) || k.is_a?(FalseClass)
                    'bool'
                  elsif k.is_a?(Fixnum)
                    'int'
                  elsif k.is_a?(Float)
                    'float'
                  else
                    'string'
                  end
              self.extra_2_value = v.to_s
            end
          end
        end
      end
    end

    def reconnect?
      reconnect.to_s.to_i != 0
    end

    def to_h
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
      }
      (1..2).each do |idx|
        name = send(:"extra_#{idx}_name")
        type = send(:"extra_#{idx}_type")
        val = send(:"extra_#{idx}_value")
        unless name.blank?
          ret[name.to_s.to_sym] =
              case type.to_s.downcase
                when 'bool'
                  %w(true on yes 1).include?(val.to_s.downcase)
                when 'int'
                  val.to_s.to_i
                when 'float'
                  val.to_s.to_f
                else
                  val.blank? ? nil : extra_1_value.to_s
              end
        end
      end
      ret
    end

    def save
      SystemConfig.set name, to_h, true
    end

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