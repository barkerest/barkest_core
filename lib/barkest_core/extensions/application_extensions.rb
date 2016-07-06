# a minor extension for the application class.
Rails::Application.class_eval do

  ##
  # Is the rails server running?
  def running?
    path = File.join(Rails.root, 'tmp/pids/server.pid')
    pid = File.exist?(path) ? File.read(path).to_i : -1
    server_running = true
    begin
      Process.getpgid pid
    rescue Errno::ESRCH
      server_running = false
    end
    server_running
  end

  ##
  # Gets the application name.
  #
  # This should be overridden in your +application.rb+ file.
  def app_name
    'BarkerEST'
  end

  ##
  # Gets the application version.
  #
  # This should be overridden in your +application.rb+ file.
  def app_version
    '0.0.1'
  end

  ##
  # Gets the application name and version.
  #
  # This can be overridden in your +application.rb+ file if you want a different behavior.
  def app_info
    "#{app_name} v#{app_version}"
  end

end
