require 'test_helper'
module BarkestCore
  class UserAlertTest < ActiveSupport::TestCase

    def setup
      @item = BarkestCore::UserAlert.new(message: 'Something you need to know.')
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require message' do
      assert_required @item, :message
    end


  end
end
