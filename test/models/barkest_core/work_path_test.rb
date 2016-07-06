require 'test_helper'

module BarkestCore
  class WorkPathTest < ActiveSupport::TestCase

    test 'should get a valid location' do
      assert_not_nil BarkestCore::WorkPath.location
      assert Dir.exist?(BarkestCore::WorkPath.location)
    end

    test 'should get valid path for temp file' do
      path = BarkestCore::WorkPath.path_for('test.file')
      assert_not_nil path
      assert_nothing_raised do
        File.write path, 'This is a test.'
        File.delete path
      end
    end


  end
end