class AccessGroupMgmtTest < ActionDispatch::IntegrationTest

  def setup
    @admin = users(:admin)
    @group = access_groups(:one)
  end

  # group management paths.
  access_tests_for [ :index, :new, :create, :show, :edit, :update, :destroy ],
                   controller: 'access_groups',
                   create_params: { access_group: { name: 'Test Group X'} },
                   update_params: { access_group: { name: 'Test Group X'} },
                   allow_anon: false,
                   allow_any_user: false,
                   allow_admin: true

  test 'update should require name' do
    log_in_as @admin
    patch access_group_path(@group), access_group: { name: '' }
    assert_template 'access_groups/edit'
    assert_select 'div#error_explanation'
  end

  test 'create should require name' do
    log_in_as @admin
    post access_groups_path, access_group: { name: '' }
    assert_template 'access_groups/new'
    assert_select 'div#error_explanation'
  end

end