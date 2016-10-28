require 'test_helper'

module BarkestCore
  class MsSqlDbUpdaterTest < ActiveSupport::TestCase

    TEST_DEFS = [
        'CREATE VIEW [something] AS SELECT 1 AS [one], \'abc\' as [two]',
        'CREATE FUNCTION [multiply] (@a INTEGER, @b INTEGER) RETURNS TABLE AS RETURN SELECT ISNULL(@a,0) * ISNULL(@b,0) AS [result]',
    ]

    class CleanupConn < ActiveRecord::Base
      self.abstract_class = true
    end

    test 'should be able to update MSSQL db' do
      updater = ::BarkestCore::MsSqlDbUpdater.new

      # add the sources.
      TEST_DEFS.each do |test_def|
        updater.add_source 20161028, test_def
      end

      cfg = BarkestCore.db_config(:ms_sql_test)
      begin
        updater.update_db(
            cfg,
            before_update: Proc.new do |conn,user|
              assert_equal cfg[:username], user
              assert_equal 0, conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}]").first['cnt']
            end,
            after_update: Proc.new do |conn,_|
              assert_not_equal 0, conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}]").first['cnt']
              assert_equal 1, conn.exec_query("SELECT [one] FROM [#{updater.table_prefix}something]").first['one']
              assert_equal 'abc', conn.exec_query("SELECT [two] FROM [#{updater.table_prefix}something]").first['two']
              assert_equal 20, conn.exec_query("SELECT [result] FROM [#{updater.table_prefix}multiply](4, 5)").first['result']
            end
        )

      rescue ::BarkestCore::MsSqlDbUpdater::NeedFullAccess => e
        skip "Invalid test MSSQL configuration: #{e.message}"
      ensure
        begin
          CleanupConn.remove_connection
          CleanupConn.establish_connection cfg
          conn = CleanupConn.connection
          conn.execute "DELETE FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}]" rescue nil
          TEST_DEFS.each do |test_def|
            begin
              test_def = ::BarkestCore::MsSqlDefinition.new(test_def)
              test_def.name_prefix = updater.table_prefix
              conn.execute test_def.drop_sql rescue nil
            rescue =>e
              nil
            end
          end
          CleanupConn.remove_connection
        rescue
          nil
        end
      end

    end


  end
end
