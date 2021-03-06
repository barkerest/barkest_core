require 'test_helper'

class AccessGroupsControllerTest < ActionController::TestCase

  setup do
    @access_group = access_groups(:one)
    @admin = users(:admin)
    log_in_as(@admin)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:access_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create access_group" do
    assert_difference('AccessGroup.count') do
      post :create, access_group: { name: 'Access Group X' }
    end

    assert_redirected_to access_groups_url
  end

  test "should show access_group" do
    get :show, id: @access_group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @access_group
    assert_response :success
  end

  test "should update access_group" do
    patch :update, id: @access_group, access_group: { name: 'Access Group X'  }
    assert_redirected_to access_groups_url
  end

  test "should destroy access_group" do
    assert_difference('AccessGroup.count', -1) do
      delete :destroy, id: @access_group
    end

    assert_redirected_to access_groups_path
  end

end
