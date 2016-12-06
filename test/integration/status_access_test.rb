class StatusAccessTest < ActionDispatch::IntegrationTest

  access_tests_for :first,
                   controller: 'status',
                   url_helper: 'status_first_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

  access_tests_for :more,
                   controller: 'status',
                   url_helper: 'status_more_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

  access_tests_for :current,
                   controller: 'status',
                   url_helper: 'status_current_path',
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true


end