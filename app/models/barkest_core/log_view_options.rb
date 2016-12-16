module BarkestCore
  class LogViewOptions
    include ActiveModel::Model
    include BarkestCore::DateParser

    attr_accessor :search, :max_records
    attr_reader :start_time, :end_time


    def min_severity=(value)
      @min_severity = BarkestCore::LogEntry::SEVERITY_LIST.index(value.to_s.upcase)
    end

    def min_severity
      return nil unless instance_variable_defined?(:@min_severity)
      return nil unless @min_severity
      BarkestCore::LogEntry::SEVERITY_LIST[@min_severity]
    end

    def min_severity_id
      return nil unless instance_variable_defined?(:@min_severity)
      @min_severity
    end

    def start_time=(value)
      @start_time = parse_for_date_column(value)
    end

    def end_time=(value)
      @end_time = parse_for_date_column(value)
    end

    def search_regex
      @search_regex ||=
          if search.blank?
            nil
          else
            /#{search.gsub('[]', '\[\]')}/i rescue nil
          end
    end

    def keep_log_entry?(log_entry)
      return false if min_severity_id && log_entry.level_id < min_severity_id
      return false if start_time && log_entry.time < start_time
      return false if end_time && log_entry.time > (end_time + 1.day)   # include events from the end date.
      return false unless search_regex.nil? || search_regex.match(log_entry.message)
      true
    end

  end
end