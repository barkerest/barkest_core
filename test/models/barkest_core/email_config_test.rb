module BarkestCore
  class EmailConfigTest < ActiveSupport::TestCase

    def setup
      @item = BarkestCore::EmailConfig.new(config_mode: :none, default_sender: 'abc@xyz.com', default_recipient: 'abc@xyz.com', default_hostname: 'xyz.com')
      @item2 = @item.dup
      @item2.config_mode = 'smtp'
      @item2.address = 'localhost'
      @item2.port = 25
      @item2.authentication = 'none'
    end

    test 'should be valid' do
      assert @item.valid?, 'item 1 is invalid'
      assert @item2.valid?, 'item 2 is invalid'
    end

    test 'should require config_mode' do
      assert_required @item, :config_mode
      assert_required @item2, :config_mode
    end

    test 'should require default_sender' do
      assert_required @item, :default_sender
      assert_required @item2, :default_sender
    end

    test 'should require default_recipient' do
      assert_required @item, :default_recipient
      assert_required @item2, :default_recipient
    end

    test 'should require default_hostname' do
      assert_required @item, :default_hostname
      assert_required @item2, :default_hostname
    end

    test 'switching to smtp should invalidate item1' do
      @item.config_mode = 'smtp'
      assert_not @item.valid?
    end

    test 'should require address for smtp' do
      assert_required @item2, :address
    end

    test 'should require port for smtp' do
      assert_required @item2, :port
    end

    test 'should require authentication for smtp' do
      assert_required @item2, :authentication
    end


  end
end