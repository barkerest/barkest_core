require 'test_helper'

module BarkestCore
  class GlobalStatusTest < ActiveSupport::TestCase

    test 'should allow running code in a block' do
      assert_not BarkestCore::GlobalStatus.locked?

      BarkestCore::GlobalStatus.lock_for do |stat|
        assert BarkestCore::GlobalStatus.locked?
        assert stat

        # set the status using our stat object.
        stat.set_status 'Hello', 10
        cur_stat = stat.get_status
        assert_equal 'Hello', cur_stat[:message]
        assert_equal 10, cur_stat[:percent].to_s.to_i

        # verify the global status reports correctly.
        cur_stat = BarkestCore::GlobalStatus.current
        assert_equal 'Hello', cur_stat[:message]
        assert_equal 10, cur_stat[:percent].to_s.to_i
      end

      # after the block, the status should be cleared.
      cur_stat = BarkestCore::GlobalStatus.current
      assert_not_equal 'Hello', cur_stat[:message]
      assert_not_equal 10, cur_stat[:percent].to_s.to_i
      assert_not BarkestCore::GlobalStatus.locked?
    end

    test 'should block code as necessary' do
      stat = BarkestCore::GlobalStatus.new
      assert_not BarkestCore::GlobalStatus.locked?
      assert stat.acquire_lock
      BarkestCore::GlobalStatus.lock_for do |my_stat|
        assert BarkestCore::GlobalStatus.locked?
        assert_not my_stat # should be false when already locked.
      end
      assert_raises BarkestCore::GlobalStatus::FailureToLock do
        BarkestCore::GlobalStatus.lock_for(true) do |my_stat|
          assert false, 'This block should not execute.'
        end
      end
      assert BarkestCore::GlobalStatus.locked?
      stat.release_lock
    end

  end
end