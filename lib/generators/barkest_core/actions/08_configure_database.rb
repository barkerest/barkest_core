BarkestCore::InstallGenerator.class_eval do
  ##
  # Generates a database.yml configuration file.
  def configure_database
    config_file = 'config/database.yml'

    attributes = [
        ['adapter', :ask_for_string, %w(sqlite3 postgresql sqlserver mysql2), 'database_adapter'],
        ['pool', :ask_for_int, (1..1000), 'connection_pool_size'],
        ['timeout', :ask_for_int, (500..300000)],
        { 'sqlite3' =>
              [
                  [ 'database', :ask_for_string, nil, 'sqlite_database', 'db/my-db.sqlite3' ]
              ],
          'postgresql' =>
              [
                  [ 'host', :ask_for_string, nil, 'pg_host' ],
                  [ 'port', :ask_for_int, (1..65535), 'pg_port', 5432 ],
                  [ 'username', :ask_for_string, nil, 'pg_username' ],
                  [ 'password', :ask_for_secret, nil, 'pg_password' ],
                  [ 'database', :ask_for_string, nil, 'pg_database' ]
              ],
          'sqlserver' =>
              [
                  [ 'host', :ask_for_string, nil, 'sql_host' ],
                  [ 'port', :ask_for_int, (1..65535), 'sql_port', 1433 ],
                  [ 'username', :ask_for_string, nil, 'sql_username' ],
                  [ 'password', :ask_for_secret, nil, 'sql_password' ],
                  [ 'database', :ask_for_string, nil, 'sql_database', 'my_db' ]
              ],
          'mysql2' =>
              [
                  [ 'host', :ask_for_string, nil, 'mysql_host' ],
                  [ 'port', :ask_for_int, (1..65535), 'mysql_port', 3306 ],
                  [ 'username', :ask_for_string, nil, 'mysql_username' ],
                  [ 'password', :ask_for_secret, nil, 'mysql_password' ],
                  [ 'database', :ask_for_string, nil, 'mysql_database', 'my_db' ]
              ]
        }
    ]

    default = {
        'adapter' => 'sqlite3',
        'pool' => 5,
        'timeout' => 5000,
        'database' => 'db/my-data.sqlite3'
    }

    configure_the 'database connection', config_file, attributes, 'adapter', default, 'barkest_core'
  end

end
