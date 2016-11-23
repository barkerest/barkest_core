require 'net/ssh'
require 'barkest_ssh'
require 'rubygems'

##
# An automatic update controller.
#
# This controller utilizes the +update_host+, +update_user+, and +update_password+ values from
# the +secrets.yml+ configuration file to perform an update of the application.
#
# This is performed via an SSH shell to the host to login as the configured user and then
# performing the various steps necessary to update the app from GIT, update the database, and precompile
# the assets.  When that is all finished, it notifies Passenger to reload the application.
#
# The status is tracked using the SystemStatusController.
#
class SystemUpdateController < ApplicationController

  before_action :require_admin

  ##
  # Perform a system update.
  #
  def new
    host = Rails.application.secrets[:update_host]
    user = Rails.application.secrets[:update_user]
    pwd = Rails.application.secrets[:update_password]
    @file_path = Rails.root.to_s
    @app_root_url = root_path
    @bundle_path = @file_path + '/bin/bundle'

    show_system_status(
        main_status: 'Updating application',
        url_on_completion: system_update_url
    ) do |status|
      if status
        unless Rails.env.test?
          begin
            File.open(BarkestCore::WorkPath.system_status_file, 'wt') do |f|
              @status_log = f

              if !host.blank? && !user.blank? && !pwd.blank?
                log_header 'Creating session'

                begin
                  BarkestSsh::SecureShell.new(
                      host: host,
                      user: user,
                      password: pwd
                  ) do |shell|

                    log_data "Session has been created.\n"

                    tmp_data = shell.exec('which ruby')
                    log_data "[WARNING: Global ruby]\n" if tmp_data == '/usr/bin/ruby'
                    log_data "Ruby Path: #{tmp_data}\n"

                    tmp_data = shell.exec('ruby -v')
                    tmp_v = /^ruby ([0-9]+\.[0-9]+)\..*$/.match(tmp_data)[1].to_s.to_f
                    log_data "[WARNING: Ruby less than 2.2.0]\n" if tmp_v < 2.2
                    log_data "Ruby Version: #{tmp_data}\n"

                    shell.exec "cd \"#{@file_path}\""

                    if Rails.env.production?

                      rtlog = Proc.new do |data, _|
                        log_data data
                        nil
                      end

                      send(:before_update, shell) if respond_to?(:before_update)
                      log_header 'Resetting app files'
                      shell.exec('git reset --hard origin/master',              &rtlog)
                      shell.exec('git clean -fd',                               &rtlog)

                      send(:before_file_update, shell) if respond_to?(:before_file_update)
                      log_header 'Updating app files'
                      shell.exec('git pull origin master',                      &rtlog)

                      send(:before_bundle, shell) if respond_to?(:before_bundle)
                      log_header 'Bundling gems'
                      shell.exec("\"#{@bundle_path}\" install --deployment",    &rtlog)

                      send(:before_db_update, shell) if respond_to?(:before_db_update)
                      log_header 'Updating database'
                      %w(db:create db:migrate).each do |cmd|
                        cmd = "\"#{@bundle_path}\" exec rake #{cmd} RAILS_ENV=production"
                        shell.exec(cmd,                                         &rtlog)
                      end

                      send(:before_db_seed, shell) if respond_to?(:before_db_seed)
                      log_header 'Seeding database'
                      cmd = 'db:seed'
                      cmd = "\"#{@bundle_path}\" exec rake #{cmd} RAILS_ENV=production"
                      shell.exec(cmd,                                           &rtlog)
                      send(:after_db_seed, shell) if respond_to?(:after_db_seed)

                      log_header 'Generating assets'
                      cmd = "\"#{@bundle_path}\" exec rake assets:precompile RAILS_ENV=production RAILS_GROUPS=assets RAILS_RELATIVE_URL_ROOT=\"#{@app_root_url}\""
                      shell.exec(cmd,                                           &rtlog)
                      send(:after_asset_gen, shell) if respond_to?(:after_asset_gen)

                      log_header 'Running automatic configuration'
                      cmd = "\"#{@bundle_path}\" exec rails generate barkest:install --force"
                      shell.exec(cmd,                                           &rtlog)
                      send(:after_config, shell) if respond_to?(:after_config)

                      log_header 'Restarting app'
                      cmd = "\"#{@bundle_path}\" exec passenger-config restart-app \"#{@file_path}\""
                      shell.exec(cmd,                                           &rtlog)
                      send(:after_update, shell) if respond_to?(:after_update)

                    else
                      log_data "Skipping actual update for non-production.\n"
                    end
                  end

                  log_data "\nUpdate process is complete.\n"
                rescue Net::SSH::AuthenticationFailed => _
                  log_data "Failed to login to the session.\nPlease verify the update credentials in your configuration.\nUpdate is aborting.\n"
                rescue StandardError => error
                  log_data "An unexpected error occurred.\n#{error}\nUpdate is aborting.\nManual application update may be required to restore functionality.\n"
                rescue => error
                  log_data "A really unexpected error has occurred.\n#{error}\nUpdate is aborting.\nManual application update may be required to restore functionality.\n"
                end
              else
                log_data "Update configuration is missing from 'secrets.yml'.\nUpdate is aborting.\n"
              end
            end
          ensure
            @status_log = nil
          end
        end
      end
    end
  end

  ##
  # Shows current information about the app.
  #
  def index
    app_gem_name = Rails.application.class.parent_name.underscore
    @additional = BarkestCore.gem_list(app_gem_name, 'rails', 'barkest*')
  end

  private

  def require_admin
    authorize! true
  end

  def log_header(label)
    @status_log.write "\n" + ('=' * 20) + label.center(24) + ('=' * 20) + "\n"
    @status_log.flush
  end

  def log_data(data)
    @status_log.write data
    @status_log.flush
  end
end
