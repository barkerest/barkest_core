require 'test_helper'
require 'digest/sha1'

class ReportsTest < ActionDispatch::IntegrationTest

  access_tests_for :index,
                   url_helper: 'barkest_core_test_report_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

  def setup
    @admin = users(:admin)
  end

  # CSV is easy, it's content won't change.
  test 'should get csv' do
    log_in_as @admin
    get barkest_core_test_report_path(format: :csv)

    assert_equal 'text/csv', response.content_type.to_s

    valid_csv = "Code,Name,Email,Date of Birth,Hire Date,Pay Rate,Hours\nSMIJOH,John Smith,j.smith@example.com,01/01/1980,05/01/2010,15.5,2260\n"
    assert_equal valid_csv, response.body
  end

  # PDF is a bit more complex, but we try our damnedest to make it consistent, even going so far as forging the creation_date.
  # The SHA1 should match up.
  test 'should get pdf' do
    log_in_as @admin
    get barkest_core_test_report_path(format: :pdf)

    assert_equal 'application/pdf', response.content_type.to_s

    valid_sha1 = '5aba48603c5e93674e67022b38524dd5d1a953c4'
    computed_sha1 = Digest::SHA1.hexdigest(response.body)
    assert_equal valid_sha1, computed_sha1
  end

  # XLSX is the same as PDF as far as testing goes.
  test 'should get xlsx' do
    log_in_as @admin
    get barkest_core_test_report_path(format: :xlsx)

    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', response.content_type.to_s

    valid_sha1 = 'e6292ab2ea16a209ccd985a00d823d15c6c6a947'
    computed_sha1 = Digest::SHA1.hexdigest(response.body)
    assert_equal valid_sha1, computed_sha1
  end


end