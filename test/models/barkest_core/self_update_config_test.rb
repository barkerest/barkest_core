module BarkestCore
  class SelfUpdateConfigTest < ActiveSupport::TestCase

    def setup
      @item = BarkestCore::SelfUpdateConfig.new(
          host: '127.0.0.1',
          user: 'somebody',
          password: 'secret',
      )
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require host' do
      assert_required @item, :host
    end

    test 'should require user' do
      assert_required @item, :user
    end

    test 'should require password' do
      assert_required @item, :password
    end

  end
end