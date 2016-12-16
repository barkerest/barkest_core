require 'time'

module BarkestCore

  ##
  # Reads a log line from a JSON log file.
  class LogEntry

    include ActiveModel::Model
    include ActiveModel::Validations
    include Comparable

    attr_reader :level, :time, :message, :app_name, :app_version, :process_id

    validates :level, presence: true
    validates :time, presence: true
    validates :message, presence: true

    SEVERITY_LIST = %w(DEBUG INFO WARN ERROR FATAL)

    ##
    # Creates a LogEntry.
    #
    # The args can either be a JSON string or a Hash.
    def initialize(*args)
      args.each do |arg|
        if arg.is_a?(String)
          arg = JSON.parse(arg).symbolize_keys rescue nil
        end
        if arg.is_a?(Hash)
          arg.each do |k,v|
            k = k.to_sym
            v = case k
                  when :level
                    v.to_sym
                  when :time
                    Time.parse(v)
                  when :process_id
                    v.to_i
                  else
                    v
                end
            instance_variable_set(:"@#{k}", v)
          end
        end
      end
    end

    ##
    # Gets the index in the log file.
    def index
      @index ||= 0
    end

    ##
    # Gets the level as a numeric ID.
    def level_id
      @level_id ||= SEVERITY_LIST.index(level.to_s.upcase) || 5
    end

    # :nodoc:
    def inspect
      "#<#{self.class.name} #{level} #{time} [#{app_name} #{app_version} (#{process_id})] #{message.length > 32 ? (message[0...32] + '...') : message}>"
    end

    # :nodoc:
    def to_s
      "#{level} #{time} [#{app_name} #{app_version} (#{process_id})] #{message}"
    end

    # :nodoc:
    def <=>(other)
      return 1 unless other.is_a?(LogEntry)
      if index == other.index
        time <=> other.time
      else
        index <=> other.index
      end
    end

    ##
    # Reads a log file consisting of JSON records.
    #
    # If no log file is specified, the default log file is assumed.
    def self.read_log(log_file = nil)
      log_file ||= Rails.root.join('log', "#{Rails.env}.log")

      ret = []

      if File.exist?(log_file)
        File.foreach(log_file, "\n").with_index do |line, index|
          line = JSON.parse(line) rescue nil
          ret << LogEntry.new(line.symbolize_keys.merge(index: index)) if line.is_a?(Hash)
        end
      end

      ret
    end

  end
end