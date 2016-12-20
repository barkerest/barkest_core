# Time is much easier to work with when you discard the time zones.
# The only place the local time matters at all is when displaying to the user on reports.
# Everywhere else, use UTC.  The default behavior should be UTC.

require 'time'


Time.class_eval do

  ##
  # Parses a time string into UTC time.
  #
  # Supports either M/D/Y H:M:S or Y-M-D H:M:S format.
  #
  # If a timezone is provided, it will be taken into account and the UTC equivalent will be returned.
  def self.utc_parse(s)
    raise ArgumentError, 'expected a time value to be provided' if s.blank?

    # If it's already a time, return the UTC variant.
    return s.utc if s.is_a?(Time)
    # If it can be converted to a time, and is not a string, convert and return the UTC variant.
    return s.to_time.utc if s.respond_to?(:to_time) && !s.is_a?(String)
    # If it is not a string, turn it into a string and parse that.
    return utc_parse(s.to_s) unless s.is_a?(String)

    dt,tm,tz,ex = s.split(' ')

    # Time only?
    if dt.include?(':')
      ex = tz
      tz = tm
      tm = dt
      dt = '1900-01-01'
    end

    yr,mon,day =
        if dt.include?('/')
          # M/D/Y
          _m,_d,_y = dt.split('/')
          _y ||= Time.now.utc.year
          [ _y, _m, _d ]
        elsif dt.include?('-')
          # Y-M-D
          dt.split('-')

          # Because we may be interacting with Spectrum users, accept these formats as well.
        elsif (/^\d{4}$/).match(dt)
          # MMDD
          [ Time.now.utc.year, dt[0...2], dt[2...4] ]
        elsif (/^\d{6}(\d{2})?$/).match(dt)
          # MMDDYY(YY)
          [ dt[4..-1], dt[0...2], dt[2...4] ]

        elsif (/^\d+(am|pm)?$/i).match(dt) && (0..24).include?(dt.to_i)
          # a single integer parsing to a valid hour, possibly with an AM/PM specifier
          ex = tz
          tz = tm
          tm = dt
          [ 1900, 1, 1 ]

        else
          # Unsupported format.
          []
        end.map { |i| i.to_i }

    raise ArgumentError, 'year is missing' unless yr
    raise ArgumentError, 'month is missing' unless mon
    raise ArgumentError, 'day is missing' unless day

    yr += 2000 if yr < 40
    yr += 1900 if yr < 100

    mon = 1 unless mon
    day = 1 unless day

    if tm
      # allow AM/PM specifier to be attached to time.
      if %w(AM PM).include?(tm[-2..-1].to_s.upcase)
        ex = tz
        tz = tm[-2..-1]
      end
    end

    hr,min,sec = tm ? tm.split(':') : []
    hr = hr ? hr.to_i : 0
    min = min ? min.to_i : 0
    sec = sec ? sec.to_f : 0.0

    if %w(AM PM).include?(tz.to_s.upcase)
      raise ArgumentError, 'hour must be between 1 and 12 for 12-hour formats' unless (1..12).include?(hr)

      tz = tz.to_s.upcase

      if tz == 'AM'
        hr = 0 if hr == 12    # only need to modify midnight.
      else
        hr += 12 unless hr == 12  # modify everything except noon.
      end

      # grab the next item from the original string.
      tz = ex
    end

    if hr == 24 && min == 0 && sec == 0
      tmp_date = Time.utc(yr,mon,day)
      raise ArgumentError, 'time component overflow' unless tmp_date.year == yr && tmp_date.month == mon && tmp_date.day == day
      tmp_date = (tmp_date + 1.day).to_time.utc
      yr = tmp_date.year
      mon = tmp_date.month
      day = tmp_date.day
      hr = 0
    end

    tz = nil if %w(UTC).include?(tz.to_s.upcase)

    result =
      if tz
        bits = (/^([+-])(\d{1,2}):?(\d{2})$/).match(tz)
        raise ArgumentError, '"+HH:MM" or "-HH:MM" expected for utc_offset' unless bits
        tz = "#{bits[1]}#{bits[2].rjust(2,'0')}:#{bits[3]}"
        Time.new(yr, mon, day, hr, min, sec, tz)
      else
        Time.utc(yr, mon, day, hr, min, sec)
      end

    raise ArgumentError, 'time component overflow' unless result.year == yr && result.month == mon && result.day == day && result.hour == hr && result.min == min && result.sec.to_i == sec.to_i

    result.utc
  end


  ##
  # Gets the date component of the time.
  def date
    return utc.date unless utc?
    Time.utc(year, month, day)
  end

  ##
  # Discards time zone information and makes
  #
  # The current time zone offset is discarded.
  # For instance, '2016-12-19 19:00:00 -05:00' becomes '2016-12-19 19:00:00 +00:00'
  def as_utc
    Time.utc(year, month, day, hour, min, sec)
  end

end

Date.class_eval do
  # :nodoc:
  alias :barkest_core_original_to_time :to_time

  ##
  # Returns the date in UTC format.
  #
  # Time portion will always be 00:00:00 UTC.
  # Dates shouldn't be TZ specific.
  def to_time
    Time.utc(year, month, day)
  end

end

