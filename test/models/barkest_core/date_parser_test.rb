require 'test_helper'

module BarkestCore
  class DateParserTest < ActiveSupport::TestCase


    test 'should parse valid date values' do
      {
          '1/1/2000'                => Time.zone.local(2000,1,1),
          '01/01/00'                => Time.zone.local(2000,1,1),
          '2000-01-01'              => Time.zone.local(2000,1,1),
          '00-01-01'                => Time.zone.local(2000,1,1),
          '0000-01-01'              => Time.zone.local(2000,1,1), # dates less than 100 are converted to 1940-2039.
          '1/1/40'                  => Time.zone.local(1940,1,1),
          '40-1-1'                  => Time.zone.local(1940,1,1),
          '12/25/2016'              => Time.zone.local(2016,12,25),
          '2016-12-25'              => Time.zone.local(2016,12,25),
          '11/01/2015 1:45 PM'      => Time.zone.local(2015,11,1),
          '2015-11-01 13:45'        => Time.zone.local(2015,11,1),
      }.each do |k,v|
        assert_equal v, BarkestCore::DateParser.parse_for_date_column(k), "#{k} should parse to #{v}"
        assert_equal v.strftime("'%Y-%m-%d'"), BarkestCore::DateParser.parse_for_date_filter(k), "#{k} should filter to #{v.strftime("'%Y-%m-%d'")}"
      end
    end

    test 'should nullify invalid date values' do
      [
          nil,
          '',
          '   ',
          '1/1',          # incomplete date
          '12/25',        # incomplete date
          '12:35',        # no date
          '20161225',     # no separators
          '1225',         # no separators
          '25/12/2016',   # DD/MM/YYYY is not supported
          '2016/12/25',   # YYYY/MM/DD is not supported
          '2016.12.25',   # YYYY.MM.DD is not supported
          '12-25-2016',   # MM-DD-YYYY is not supported
          '25-12-2016',   # DD-MM-YYYY is not supported
          '12.25.2016',   # MM.DD.YYYY is not supported
          '0/0/0000',     # Invalid day & month.
          '2/30/2000',    # Invalid day.
          '13/13/2000',   # Invalid month.
          'Sunday, December 25, 2016',  # only numeric dates are supported
          'December 25, 2016',          # only numeric dates are supported
      ].each do |v|
        assert_nil BarkestCore::DateParser.parse_for_date_column(v), "#{v.inspect} should parse to nil"
        assert_equal "NULL", BarkestCore::DateParser.parse_for_date_filter(v), "#{v.inspect} should parse to NULL"
      end
    end

    test 'should parse valid time values' do
      {
          '1/1/2000 00:00'          => Time.zone.local(2000,1,1),
          '01/01/00 00:00'          => Time.zone.local(2000,1,1),
          '2000-01-01 00:00'        => Time.zone.local(2000,1,1),
          '00-01-01 00:00'          => Time.zone.local(2000,1,1),
          '1/1/40 00:00'            => Time.zone.local(1940,1,1),
          '40-1-1 00:00'            => Time.zone.local(1940,1,1),
          '12/25/2016 00:00'        => Time.zone.local(2016,12,25),
          '2016-12-25 00:00'        => Time.zone.local(2016,12,25),
          '11/01/2015 1:45 PM'      => Time.zone.local(2015,11,1,13,45),
          '2015-11-01 13:45'        => Time.zone.local(2015,11,1,13,45),
          '12:15 AM'                => Time.zone.local(1900,1,1,0,15),
          '12:15 PM'                => Time.zone.local(1900,1,1,12,15),
          '00:15'                   => Time.zone.local(1900,1,1,0,15),
          '12:15'                   => Time.zone.local(1900,1,1,12,15),
          '2:30 PM'                 => Time.zone.local(1900,1,1,14,30),
          '2:30 AM'                 => Time.zone.local(1900,1,1,2,30),
          '18:45:50'                => Time.zone.local(1900,1,1,18,45,50),
          '6:45:50 AM'              => Time.zone.local(1900,1,1,6,45,50),
          '6:45:50 PM'              => Time.zone.local(1900,1,1,18,45,50),
          '12/25/2016 9:05:10 AM'   => Time.zone.local(2016,12,25,9,5,10),
          '12/25/2016 9:05:10 PM'   => Time.zone.local(2016,12,25,21,5,10),
          '1/1/2000 24:00'          => Time.zone.local(2000,1,2,0,0),   # 24:00 is 00:00 the next day.
      }.each do |k,v|
        assert_equal v, BarkestCore::DateParser.parse_for_time_column(k), "#{k} should parse to #{v}"
        assert_equal v.strftime("'%Y-%m-%d %H:%M:%S'"), BarkestCore::DateParser.parse_for_time_filter(k), "#{k} should filter to #{v.strftime("'%Y-%m-%d %H:%M:%S'")}"
      end
    end

    test 'should nullify invalid time values' do
      [
          nil,
          '',
          '   ',
          '1/1 00:00',          # incomplete date
          '12/25 00:00',        # incomplete date
          '20161225 00:00',     # no date separators
          '1225 00:00',         # no date separators
          '1218',               # no time separators
          '25/12/2016 00:00',   # DD/MM/YYYY is not supported
          '2016/12/25 00:00',   # YYYY/MM/DD is not supported
          '2016.12.25 00:00',   # YYYY.MM.DD is not supported
          '12-25-2016 00:00',   # MM-DD-YYYY is not supported
          '25-12-2016 00:00',   # DD-MM-YYYY is not supported
          '12.25.2016 00:00',   # MM.DD.YYYY is not supported
          '0/0/0000 00:00',     # Invalid day & month.
          '2/30/2000 00:00',    # Invalid day.
          '13/13/2000 00:00',   # Invalid month.
          '25:00',              # invalid hour
          '23:66',              # invalid minute
          '23:59:66',           # invalid second
          '13:00 PM',           # invalid mixed 12/24
          '13:00 AM',           # invalid mixed 12/24
          '00:00 PM',           # invalid mixed 12/24
          '00:00 AM',           # invalid mixed 12/24
          'Sunday, December 25, 2016 12:18 AM',  # only numeric dates are supported
          'December 25, 2016 12:18 AM',          # only numeric dates are supported
      ].each do |v|
        assert_nil BarkestCore::DateParser.parse_for_date_column(v), "#{v.inspect} should parse to nil"
        assert_equal "NULL", BarkestCore::DateParser.parse_for_date_filter(v), "#{v.inspect} should parse to NULL"
      end
    end

  end
end