require 'test_helper'

module BarkestCore
  class MsSqlDbUpdaterTest < ActiveSupport::TestCase

    TEST_DEFS = [
        'CREATE TABLE [alpha_beta] ( [id] INTEGER IDENTITY NOT NULL PRIMARY KEY, [name] VARCHAR(30) NOT NULL )',
        'CREATE VIEW [something] AS SELECT 1 AS [one], \'abc\' as [two]',
        'CREATE FUNCTION [multiply] (@a INTEGER, @b INTEGER) RETURNS TABLE AS RETURN SELECT ISNULL(@a,0) * ISNULL(@b,0) AS [result]',
        'CREATE VIEW [alpha_bravo] AS SELECT COUNT(*) AS [beta_count] FROM [@Z~alpha_beta]',    # referencing another object.
        # A sample procedure that shows how a procedure can be used to enact more diverse updates.
        # For instance, incremental table updates could be done with an ALTER, but they wouldn't necessarily be safe.
        # Inside a procedure you can check for column existence and update as necessary, making the procedure safe to be
        # called multiple times.  The updater only sees the procedure so it won't try to manage the updates carried out
        # by the procedure.
        <<-EOPROC
CREATE PROCEDURE [add_delta]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @cnt INTEGER;
  SELECT @cnt=ISNULL((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS C WHERE C.[TABLE_NAME]='@Z~alpha_beta' AND C.[COLUMN_NAME]='delta'), 0);
  IF @cnt <> 1
  BEGIN
    ALTER TABLE [@Z~alpha_beta] ADD [delta] FLOAT;
    EXEC sp_sqlexec 'UPDATE [@Z~alpha_beta] SET [delta] = 1.0';
    RETURN 1;
  END
  ELSE
  BEGIN
    RETURN 0;
  END
END
EOPROC

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
      cntr = 0
      begin
        updater.update_db(
            cfg,
            before_update: Proc.new do |conn,user|
              assert_equal cfg[:username], user
              cntr = conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}]").first['cnt']
              updater.sources.each do |src|
                assert_equal 0, conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}] WHERE [object_name]='#{src.prefixed_name}'").first['cnt']
                assert_not conn.object_exists?(src.prefixed_name)
              end
            end,
            after_update: Proc.new do |conn,_|
              assert_equal cntr + TEST_DEFS.count, conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}]").first['cnt']
              updater.sources.each do |src|
                assert_equal 1, conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}] WHERE [object_name]='#{src.prefixed_name}'").first['cnt']
                assert conn.object_exists?(src.prefixed_name)
              end
              assert_not_equal 0, conn.exec_query("SELECT COUNT(*) AS [cnt] FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}]").first['cnt']
              assert_equal 1, conn.exec_query("SELECT [one] FROM [#{updater.object_name 'something'}]").first['one']
              assert_equal 'abc', conn.exec_query("SELECT [two] FROM [#{updater.object_name 'something'}]").first['two']
              assert_equal 20, conn.exec_query("SELECT [result] FROM [#{updater.object_name 'multiply'}](4, 5)").first['result']

              (1..5).each do |i|
                conn.exec_query "INSERT INTO [#{updater.object_name 'alpha_beta'}] ([name]) VALUES ('Number #{i}')"
              end

              # pass one, a return value of 1 indicates the SP made the necessary changes.
              assert_equal 1, conn.exec_sp("EXECUTE [#{updater.object_name 'add_delta'}]")
              # pass two, a return value of 0 indicates the SP didn't need to make changes.
              assert_equal 0, conn.exec_sp("EXECUTE [#{updater.object_name 'add_delta'}]")

              # Now we can directly access the new [delta] fields added to our table.
              assert_equal 5, conn.exec_query("SELECT COUNT(*) AS [delta_count] FROM [#{updater.object_name 'alpha_beta'}] WHERE [delta]=1.0").first['delta_count']
              # And the view should still work as well.
              assert_equal 5, conn.exec_query("SELECT [beta_count] FROM [#{updater.object_name 'alpha_bravo'}]").first['beta_count']
            end
        )

      rescue ::BarkestCore::MsSqlDbUpdater::NeedFullAccess => e
        skip "Invalid test MSSQL configuration: #{e.message}"
      ensure
        begin
          CleanupConn.remove_connection
          CleanupConn.establish_connection cfg
          conn = CleanupConn.connection
          updater.sources.reverse.each do |test_def|
            begin
              conn.execute "DELETE FROM [#{::BarkestCore::MsSqlDbUpdater::VERSION_TABLE_NAME}] WHERE [object_name]='#{test_def.prefixed_name}'" rescue nil
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
