require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @user           = users(:standard)
    @other_user     = users(:basic)
    @admin          = users(:admin)
    @can_delete     = users(:disabled)
    @cannot_delete  = users(:recently_disabled)
  end

  test 'should redirect index when not logged in' do
    get users_path
    assert_redirected_to login_url
  end

  test 'index including pagination' do
    log_in_as @user
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    User.enabled.sorted.paginate(page: 1).each do |user|
      assert_select 'a[href=?] i', disable_user_path(user), count: 0
      assert_select 'a[href=?]', user_path(user), text: user.name
    end
    get user_path(@other_user)
    assert_template 'users/show'
  end

  test 'index disabled for non-admin' do
    original = BarkestCore.lock_down_users
    begin
      BarkestCore.lock_down_users = true
      log_in_as @user
      get users_path
      assert_redirected_to root_url
      get user_path(@other_user)
      assert_redirected_to root_url
    ensure
      BarkestCore.lock_down_users = original
    end
  end

  test 'index for admin' do
    log_in_as @admin
    get users_path
    User.all.sorted.paginate(page: 1).each do |user|
      # disabled users should have a delete link
      assert_select 'a[href=?]>i', user_path(user), count: (user.enabled? ? 0 : 1)

      # enabled users (except the current one) should have a disable link
      assert_select 'a[href=?]>i', disable_user_path(user), count: ((user.enabled? && !current_user?(user)) ? 1 : 0)

      # all users should have a link to their profile page.
      assert_select 'a[href=?]', user_path(user), text: user.name
    end
  end


end

