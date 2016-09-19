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

      # we should be able to write and delete the test file successfully.
      # ironically, this is the same code used in the WorkPath class
      # to verify the path is usable, which makes this redundant, but
      # testing is supposed to be thorough, so I'm leaving it in place.
      File.write path, 'This is a test.'
      File.delete path

    end


  end
end