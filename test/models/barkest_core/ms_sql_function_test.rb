require 'test_helper'
module BarkestCore
  class MsSqlFunctionTest < ActiveSupport::TestCase

    class MyTestFunctionParentTable < ActiveRecord::Base
      self.abstract_class = true
      establish_connection BarkestCore.db_config(:ms_sql_test)
    end

    class MyTestFunction < ::BarkestCore::MsSqlFunction

    end

    MY_TEST_FUNCTION_NAME = 'zz_barkest_core_test_function'

    MY_TEST_FUNCTION_DEFINITION = <<-EOSQL
CREATE FUNCTION #{MY_TEST_FUNCTION_NAME}(
  @alpha INTEGER,
  @bravo VARCHAR(100),
  @charlie DATETIME
) RETURNS TABLE AS RETURN
SELECT
  LEN(ISNULL(@bravo,'')) AS [bravo_len],
  LEN(ISNULL(@bravo,'')) * ISNULL(@alpha,0) AS [alpha_bravo],
  CONVERT(FLOAT, LEN(ISNULL(@bravo, ''))) / 100.0 AS [bravo_len_pct],
  CONVERT(BIT, CASE
    WHEN @alpha > 25 THEN 1
    ELSE 0
  END) AS [alpha_gt_25],
  ISNULL(@alpha,0) AS [alpha],
  ISNULL(@bravo,'') AS [bravo],
  ISNULL(@charlie, GETDATE()) AS [charlie]
    EOSQL

    MY_TEST_FUNCTION_PARAMS = {
        :alpha=>{:type=>:integer, :data_type=>'integer'},
        :bravo=>{:type=>:string, :data_type=>'varchar(100)'},
        :charlie=>{:type=>:datetime, :data_type=>'datetime'}
    }

    MY_TEST_FUNCTION_COLUMNS = [
        {:name=>'bravo_len',      :key=>:bravo_len,     :data_type=>'int',            :type=>:integer},
        {:name=>'alpha_bravo',    :key=>:alpha_bravo,   :data_type=>'int',            :type=>:integer},
        {:name=>'bravo_len_pct',  :key=>:bravo_len_pct, :data_type=>'float',          :type=>:float},
        {:name=>'alpha_gt_25',    :key=>:alpha_gt_25,   :data_type=>'bit',            :type=>:boolean},
        {:name=>'alpha',          :key=>:alpha,         :data_type=>'int',            :type=>:integer},
        {:name=>'bravo',          :key=>:bravo,         :data_type=>'varchar(100)',   :type=>:string,     :length=>100},
        {:name=>'charlie',        :key=>:charlie,       :data_type=>'datetime',       :type=>:datetime}
    ]

    test 'ms sql function parsing' do
      begin
        # set the connection handler
        MyTestFunction.use_connection MyTestFunctionParentTable
        # create the UDF
        MyTestFunction.connection.execute MY_TEST_FUNCTION_DEFINITION
      rescue Exception => e
        skip "Invalid test MSSQL configuration: #{e.message}"
      end

      begin
        # parse the function
        MyTestFunction.function_name = MY_TEST_FUNCTION_NAME

        # params should match up.
        MyTestFunction.parameters.each do |param_key, param_attrib|
          valid = MY_TEST_FUNCTION_PARAMS[param_key]
          assert_not_nil valid, "Function has extra #{param_key} parameter."
          assert_equal valid[:type], param_attrib[:type], "Parameter #{param_key} has the wrong type."
          assert_equal valid[:data_type], param_attrib[:data_type], "Parameter #{param_key} has the wrong data_type."
        end

        MY_TEST_FUNCTION_PARAMS.each do |param_key, _|
          assert_not_nil MyTestFunction.parameters[param_key], "Function is missing #{param_key} parameter."
        end

        # columns should match up.
        MyTestFunction.columns.each do |attribs|
          valid = MY_TEST_FUNCTION_COLUMNS.find{|v| v[:name] == attribs[:name]}
          assert_not_nil valid, "Function has extra #{attribs[:name]} column."
          assert_equal valid[:key], attribs[:key], "Column #{attribs[:name]} has the wrong key."
          assert_equal valid[:data_type], attribs[:data_type], "Column #{attribs[:name]} has the wrong data type."
          assert_equal valid[:type], attribs[:type], "Column #{attribs[:name]} has the wrong type."
          if valid[:length]
            assert_equal valid[:length], attribs[:length], "Column #{attribs[:name]} has the wrong length."
          end
        end

        MY_TEST_FUNCTION_COLUMNS.each do |valid|
          col = MyTestFunction.columns.find{|v| v[:name] == valid[:name]}
          assert_not_nil col, "Function is missing #{valid[:name]} column."
        end

        # and then tests.
        [
            [10, 'Hello', 5.days.ago],
            [61, 'Some test text to test with!', Time.zone.now + 5.days]
        ].each do |(alpha, bravo, charlie)|

          result = MyTestFunction.select(alpha: alpha, bravo: bravo, charlie: charlie)

          assert_not_nil result
          assert_equal 1, result.count
          result = result.first

          assert_equal bravo.length, result.bravo_len
          assert_equal alpha * bravo.length, result.alpha_bravo
          assert_equal bravo.length * 0.01, result.bravo_len_pct
          assert_equal alpha > 25, result.alpha_gt_25?
        end

      ensure
        MyTestFunction.connection.execute "DROP FUNCTION #{MY_TEST_FUNCTION_NAME}"
      end
    end


  end
end