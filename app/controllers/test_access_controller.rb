##
# A controller used specifically to test authentication and authorization.
class TestAccessController < ApplicationController

  before_action :valid_user

  ##
  # Tests an action that doesn't require a user to be logged in.
  def allow_anon
  end

  ##
  # Tests an action that requires a user to be logged in.
  def require_user
  end

  ##
  # Tests an action that requires a user that is an administrator to be logged in.
  def require_admin
  end

  ##
  # Tests an action that requires a user that is a member of one of the groups to be logged in.
  #
  # The valid groups are 'group 1', 'group 2', and 'group 3'.
  def require_group_x
  end

  private

  def valid_user
    case action_name.to_sym
      when :require_user
        authorize!
      when :require_admin
        authorize! true
      when :require_group_x
        authorize! 'group 1', 'group 2', 'group 3'
      else
        true
    end
  end

end
