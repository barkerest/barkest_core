
##
# This controller makes it easy to edit the system configuration for email, authentication,
# and additional database connections.
#
# Extend this class and add additional configuration items if needed.
# New configuration items should be added as paired methods.
#
#   # GET: /system_config/my_config_item
#   def show_my_config_item
#     ...
#   end
#
#   # POST: /system_config/my_config_item
#   def update_my_config_item
#     ...
#   end
#
# If the config item requires an ID parameter, use the requires_id helper.
#   requires_id :my_config_item
#
class SystemConfigController < ApplicationController

  private

  def self.id_config_types
    @id_config_types ||= {}
  end

  protected

  ##
  # Sets a config type to require an id parameter.
  def self.requires_id(config_type, id_provider)
    config_type = config_type.to_s.to_sym
    raise 'provider cannot be nil' unless id_provider
    id_config_types[config_type] = id_provider
  end

  public

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

  requires_id :database, '::BarkestCore::DatabaseConfig.registered'

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

  ##
  # GET /system_config/self_update
  def show_self_update
    @config = BarkestCore::SelfUpdateConfig.load
  end

  ##
  # POST /system_config/self_update
  def update_self_update
    @config = get_self_update_params

    if @config.valid?
      if @config.save
        flash[:success] = 'The configuration has been saved.'
        redirect_to system_config_url
      else
        flash[:danger] = 'Failed to save the configuration.'
        render 'show_self_update'
      end
    else
      render 'show_self_update'
    end
  end

  ##
  # Gets all known configuration items.
  def self.get_config_items
    ret = {}
    rex = /^(show|update)_/

    id_config_types.each { |item, provider| ret[item] = { require_id: true, id_provider: provider } }

    self.instance_methods.sort.each do |meth|
      meth = meth.to_s
      if rex.match(meth)
        action,_,item = meth.partition('_')
        action = action.to_sym
        item = item.to_sym
        ret[item] ||= {}
        ret[item][action] = true
      end
    end

    ret.keep_if{ |_,v| v[:show] && v[:update] }

    ret.each do |k,v|
      ret[k][:route_name] = :"system_config_#{k}"
      ret[k][:path_helper] = :"system_config_#{k}_path"
      ret[k][:url_helper] = :"system_config_#{k}_url"
    end

    ret
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
        :encoding, :database,
        :extra_1_name, :extra_1_type, :extra_1_value, :extra_1_label,
        :extra_2_name, :extra_2_type, :extra_2_value, :extra_2_label,
        :extra_3_name, :extra_3_type, :extra_3_value, :extra_3_label,
        :extra_4_name, :extra_4_type, :extra_4_value, :extra_4_label,
        :extra_5_name, :extra_5_type, :extra_5_value, :extra_5_label,
        :update_username, :update_password
    ))
  end

  def get_self_update_params
    BarkestCore::SelfUpdateConfig.new(params.require(:barkest_core_self_update_config).permit(:host, :port, :user, :password))
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
