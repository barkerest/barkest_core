require 'test_helper'

class SystemConfigTest < ActiveSupport::TestCase

  TEST_VALUES = [
      'world',
      :world,
      1234,
      56.789,
      nil,
      true,
      false,
      [ 1, 2, 3 ],
      {a: 1, b: 2, c: 3},
      Time.now
  ]

  def setup
    @item = SystemConfig.new(key: 'hello')
  end

  test 'should be valid' do
    assert @item.valid?
  end

  test 'should allow setting value to various types' do
    TEST_VALUES.each do |test_value|
      @item.value = test_value
      @item.save!
      assert_equal test_value, @item.value
    end
  end

  test 'should require key' do
    assert_required @item, :key
    assert_not SystemConfig.set('', '')
  end

  test 'key should not be too long' do
    assert_max_length @item, :key, 128
  end

  test 'key should be unique' do
    assert_uniqueness @item, :key
  end

  test 'get and set should support encryption' do
    TEST_VALUES.each do |test_value|
      SystemConfig.set 'abc', test_value, true
      test = SystemConfig.find_by(key: 'abc')

      assert_not_nil test

      assert_not_equal test_value, test.value
      assert_equal test_value, SystemConfig.get('abc')

      assert test.value.is_a?(Hash)
      assert test.value.keys.include?(:encrypted_value)
    end
  end

  test 'get and set methods should work' do
    TEST_VALUES.each do |test_value|
      SystemConfig.set 'abc', test_value
      SystemConfig.set 'Xyz', test_value
      assert_equal test_value, SystemConfig.get('abc')
      assert_equal test_value, SystemConfig.get('xyz')
      assert_equal test_value, SystemConfig.get('ABC')
      assert_equal test_value, SystemConfig.get('XYZ')
    end
  end

end
