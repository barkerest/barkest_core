
# Add some extensions to the route mapper.
ActionDispatch::Routing::Mapper.class_eval do

  ##
  # Installs all known Barkest routes.
  #
  # Basically every Barkest plugin should define a 'barkest_' helper in the routing mapper class,
  # so this method simply finds and executes those helpers.
  def barkest(options = {})
    self.methods.each do |method|
      if method.to_s.index('barkest_') == 0
        send method, options
      end
    end
  end

  ##
  # Installs the BarkestCore routes.
  def barkest_core(options = {})
    options = { path: options } if options.is_a?(String)
    options = (options || {}).symbolize_keys

    path = options[:path].blank? ? '/' : options[:path].to_s
    path = '/' + path unless path[0] == '/'

    scope path: path do
      if Rails.env.test? || Rails.env.development?
        scope as: :barkest_core do
          # test routes
          get     'test_access/allow_anon'
          get     'test_access/require_user'
          get     'test_access/require_admin'
          get     'test_access/require_group_x'
          get     'test_report' => 'test_report#index'
        end
      end

      # contact form
      get       'contact'                 => 'contact#index'
      post      'contact'                 => 'contact#create'

      # login/logout
      get       'login'                   => 'sessions#new',      as: :login
      post      'login'                   => 'sessions#create'
      delete    'logout'                  => 'sessions#destroy',  as: :logout

      # user management
      get       'signup'                  => 'users#new',         as: :signup
      post      'signup'                  => 'users#create'
      resources :users do
        member do
          get   'disable',                action: :disable_confirm
          patch 'disable',                action: :disable
          put   'disable',                action: :disable
          patch 'enable',                 action: :enable
          put   'enable',                 action: :enable
        end
      end

      # account activation route.
      get       'account_activation/:id'  => 'account_activations#edit', as: 'edit_account_activation'

      # password reset routes.
      resources :password_resets,         only: [:new, :create, :edit, :update]

      # group management
      resources :access_groups

      # status paths
      get       'status/current'          => 'status#current'
      get       'status/first'            => 'status#first'
      get       'status/more'             => 'status#more'
      get       'status/test(/:flag)'     => 'status#test',         as: :status_test

      # system update paths
      get       'system_update/new'
      get       'system_update'           => 'system_update#index', as: :system_update

      # system configuration paths
      get       'system_config'               => 'system_config#index',             as: :system_config
      post      'system_config/restart'       => 'system_config#restart',           as: :system_config_restart
      get       'system_config/auth'          => 'system_config#show_auth',         as: :system_config_auth
      post      'system_config/auth'          => 'system_config#update_auth'
      get       'system_config/email'         => 'system_config#show_email',        as: :system_config_email
      post      'system_config/email'         => 'system_config#update_email'
      get       'system_config/database/:id'  => 'system_config#show_database',     as: :system_config_database
      post      'system_config/database/:id'  => 'system_config#update_database'
      get       'system_config/self_update'   => 'system_config#show_self_update',  as: :system_config_self_update
      post      'system_config/self_update'   => 'system_config#update_self_update'

    end
  end


end