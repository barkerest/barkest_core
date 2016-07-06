class TestAccessController < ApplicationController

  before_action :valid_user

  def allow_anon
  end

  def require_user
  end

  def require_admin
  end

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
