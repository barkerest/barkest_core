
##
# This controller makes it easy to edit the system configuration for email, authentication,
# and additional database connections.
class SystemConfigController < ApplicationController

  before_action :require_admin
  before_action :validate_db_id, only: [ :show_database, :update_database ]

  ##
  # GET /system_config
  def index

  end

  ##
  # POST /system_config/restart
  def restart
    BarkestCore.request_restart
    redirect_to system_config_url
  end

  ##
  # GET /system_config/auth
  def show_auth
    @auth_params = BarkestCore::AuthConfig.new(BarkestCore.auth_config)
  end

  ##
  # POST /system_config/auth
  def update_auth
    @auth_params = get_auth_params

    if @auth_params.valid?
      if @auth_params.save
        flash[:safe_success] = 'The configuration has been saved.<br>The app will need to be restarted to use the new configuration.'
        redirect_to system_config_url
      else
        flash.now[:danger] = 'Failed to save the configuration.'
        render 'show_auth'
      end
    else
      render 'show_auth'
    end
  end

  ##
  # GET /system_config/email
  def show_email
    @email_config = BarkestCore::EmailConfig.new(BarkestCore.email_config)
  end

  ##
  # POST /system_config/email
  def update_email
    @email_config = get_email_params

    if @email_config.valid?
      if @email_config.save
        flash[:safe_success] = 'The configuration has been saved.<br>The app will need to be restarted to use the new configuration.'
        redirect_to system_config_url
      else
        flash.now[:danger] = 'Failed to save the configuration.'
        render 'show_email'
      end
    else
      render 'show_email'
    end
  end

  ##
  # GET /system_config/database/db_name
  def show_database
    @db_config = BarkestCore::DatabaseConfig.new(@db_id, BarkestCore.db_config(@db_id))
  end

  ##
  # POST /system_config/database/db_name
  def update_database
    @db_config = get_db_params

    if @db_config.valid?
      if @db_config.save
        flash[:safe_success] = 'The configuration has been saved.<br>The app will need to be restarted to use the new configuration.'
        redirect_to system_config_url
      else
        flash.now[:danger] = 'Failed to save the configuration.'
        render 'show_database'
      end
    else
      render 'show_database'
    end
  end


  private

  def require_admin
    authorize! true
  end

  def get_auth_params
    BarkestCore::AuthConfig.new(params.require(:barkest_core_auth_config).permit(
        :enable_db_auth, :enable_ldap_auth, :ldap_host, :ldap_port, :ldap_base_dn, :ldap_ssl,
        :ldap_browse_user, :ldap_browse_password, :ldap_auto_activate, :ldap_system_admin_groups
    ))
  end

  def get_email_params
    BarkestCore::EmailConfig.new(params.require(:barkest_core_email_config).permit(
        :config_mode, :default_sender, :default_recipient, :default_hostname,
        :address, :port, :authentication, :ssl, :enable_starttls_auto,
        :user_name, :password
    ))
  end

  def get_db_params
    BarkestCore::DatabaseConfig.new(@db_id, params.require(:barkest_core_database_config).permit(
        :adapter, :host, :port, :timeout, :pool, :reconnect, :username, :password,
        :encoding, :database, :extra_1_name, :extra_1_type, :extra_1_value, :extra_2_name,
        :extra_2_type, :extra_2_value,
    ))
  end

  def validate_db_id
    @db_id = params[:id].to_s.downcase
    if @db_id.blank?
      flash[:danger] = 'Database ID must be specified.'
      redirect_to system_config_url
    elsif @db_id == 'barkest_core'
      flash[:danger] = 'Database ID cannot be barkest_core.'
      redirect_to system_config_url
    elsif BarkestCore.db_config_is_file_based?(@db_id)
      flash[:danger] = "Configuration for #{@db_id} is stored in database.yml."
      redirect_to system_config_url
    end
  end

end
