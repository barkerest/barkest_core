module BarkestCore
  class DatabaseConfigTest < ActiveSupport::TestCase

    def setup
      @item = BarkestCore::DatabaseConfig.new('my_db', adapter: :sqlite3, database: 'mydb.sqlite', pool: 5, timeout: 5000)
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require name' do
      assert_required @item, :name
    end

    test 'should require adapter' do
      assert_required @item, :adapter
    end

    test 'should require database' do
      assert_required @item, :database
    end

    test 'should require pool' do
      assert_required @item, :pool
    end

    test 'should require timeout' do
      assert_required @item, :timeout
    end

  end
end