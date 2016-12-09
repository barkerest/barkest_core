# This will provide the "Fake Settings" link on the configuration page.
SystemConfigController.class_eval do

  def show_fake

  end

  def update_fake
    redirect_to system_config_url
  end

end
