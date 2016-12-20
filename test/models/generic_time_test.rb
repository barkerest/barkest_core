require 'test_helper'

class GenericTimeTest < ActiveSupport::TestCase

  test 'should handle time objects' do
    [
        Time.utc(2016, 12, 19, 15, 45),
        Time.new(2016, 12, 19, 15, 45),
        Time.new,
        Time.zone.now,
        Time.zone.local(2016, 12, 19, 15, 45),
        Date.today,
    ].each do |item|
      assert_equal item.to_time.utc, Time.utc_parse(item), "Item #{item.inspect} does not parse to #{item.to_time.utc.inspect}."
    end
  end

  test 'should handle ISO formatted strings' do
    {
        '2016-12-19'              => Time.utc(2016, 12, 19),
        '2016-12-19 15:45'        => Time.utc(2016, 12, 19, 15, 45),
        '2016-12-19 15:45:15'     => Time.utc(2016, 12, 19, 15, 45, 15),
        '2016-12-19 15:45 -500'   => Time.utc(2016, 12, 19, 20, 45),
        '2016-12-19 15:45 -0500'  => Time.utc(2016, 12, 19, 20, 45),
        '2016-12-19 15:45 -05:00' => Time.utc(2016, 12, 19, 20, 45),
        '2016-12-19 20:45 +500'   => Time.utc(2016, 12, 19, 15, 45),
        '2016-12-19 20:45 +0500'  => Time.utc(2016, 12, 19, 15, 45),
        '2016-12-19 20:45 +05:00' => Time.utc(2016, 12, 19, 15, 45),
        '2016-12-19 20:45 UTC'    => Time.utc(2016, 12, 19, 20, 45),
    }.each do |key, val|
      assert_equal val, Time.utc_parse(key), "Item #{key} does not parse to #{val.inspect}."
    end
  end

  test 'should handle other select formats' do
    {
        '16-12-19'                => Time.utc(2016, 12, 19),
        '12/19/16'                => Time.utc(2016, 12, 19),
        '12/19/2016'              => Time.utc(2016, 12, 19),
        '12/19'                   => Time.utc(Time.now.utc.year, 12, 19),
        '1219'                    => Time.utc(Time.now.utc.year, 12, 19),
        '121916'                  => Time.utc(2016, 12, 19),
        '12192016'                => Time.utc(2016, 12, 19),
        '12/19/16 15:45'          => Time.utc(2016, 12, 19, 15, 45),
        '12/19/16 3:45pm'         => Time.utc(2016, 12, 19, 15, 45),
        '12/19/16 3:45 pm'        => Time.utc(2016, 12, 19, 15, 45),
        '12/19/16 3:45 pm -500'   => Time.utc(2016, 12, 19, 20, 45),
        '12/19/16 12 am'          => Time.utc(2016, 12, 19, 0, 0),
        '12/19/16 12 pm'          => Time.utc(2016, 12, 19, 12, 0),
        '12/19/16 3 am'           => Time.utc(2016, 12, 19, 3, 0),
        '12/19/16 3 pm'           => Time.utc(2016, 12, 19, 15, 0),
        '15:45:30'                => Time.utc(1900, 1, 1, 15, 45, 30),
        '15:45:30 -500'           => Time.utc(1900, 1, 1, 20, 45, 30),
        '12'                      => Time.utc(1900, 1, 1, 12, 0),
        '12am'                    => Time.utc(1900, 1, 1, 0, 0),
        '12 am'                   => Time.utc(1900, 1, 1, 0, 0),
        '12PM'                    => Time.utc(1900, 1, 1, 12, 0),
        '12 PM -500'              => Time.utc(1900, 1, 1, 17, 0),
        '3:45 pm'                 => Time.utc(1900, 1, 1, 15, 45),
        '3:45 pm -05:00'          => Time.utc(1900, 1, 1, 20, 45),
    }.each do |key, val|
      assert_equal val, Time.utc_parse(key), "Item #{key} does not parse to #{val.inspect}."
    end
  end

end