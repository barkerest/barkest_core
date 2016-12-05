require File.expand_path('../../../../app/helpers/barkest_core/application_helper', __FILE__)
require File.expand_path('../../../../app/helpers/barkest_core/sessions_helper', __FILE__)

# include all the standard application helpers.
ActiveSupport::TestCase.include BarkestCore::ApplicationHelper
ActiveSupport::TestCase.include BarkestCore::SessionsHelper

# add a few simple extensions for testing.
ActiveSupport::TestCase.class_eval do

  ##
  # Tests a specific field for presence validation.
  #
  # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
  #
  # +attribute+ must provide the name of a valid attribute in the model.
  #
  # +message+ is optional, but if provided it will be postfixed with the failure reason.
  def assert_required(model, attribute, message = nil)
    original_value = model.send(attribute)
    original_valid = model.valid?
    is_string = original_value.is_a?(String)
    setter = :"#{attribute}="
    model.send setter, nil
    assert_not model.valid?, message ? (message + ': (nil)') : "Should not allow #{attribute} to be set to nil."
    if is_string
      model.send setter, ''
      assert_not model.valid?, message ? (message + ": ('')") : "Should not allow #{attribute} to be set to empty string."
      model.send setter, '   '
      assert_not model.valid?, message ? (message + ": ('   ')") : "Should not allow #{attribute} to be set to blank string."
    end
    model.send setter, original_value
    if original_valid
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end
  end

  ##
  # Tests a specific field for maximum length restriction.
  #
  # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
  #
  # +attribute+ must provide the name of a valid attribute in the model.
  #
  # +max_length+ is the maximum valid length for the field.
  #
  # +message+ is optional, but if provided it will be postfixed with the failure reason.
  def assert_max_length(model, attribute, max_length, message = nil, options = {})
    original_value = model.send(attribute)
    original_valid = model.valid?
    setter = :"#{attribute}="

    if message.is_a?(Hash)
      options = message.merge(options || {})
      message = nil
    end

    pre = options[:start].to_s
    post = options[:end].to_s
    len = max_length - pre.length - post.length

    # try with maximum valid length.
    value = pre + ('a' * len) + post
    model.send setter, value
    assert model.valid?, message ? (message + ": !(#{value.length})") : "Should allow a string of #{value.length} characters."

    # try with one extra character.
    value = pre + ('a' * (len + 1)) + post
    model.send setter, value
    assert_not model.valid?, message ? (message + ": (#{value.length})") : "Should not allow a string of #{value.length} characters."

    model.send setter, original_value
    if original_valid
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end
  end

  ##
  # Tests a specific field for maximum length restriction.
  #
  # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
  #
  # +attribute+ must provide the name of a valid attribute in the model.
  #
  # +max_length+ is the maximum valid length for the field.
  #
  # +message+ is optional, but if provided it will be postfixed with the failure reason.
  def assert_min_length(model, attribute, min_length, message = nil, options = {})
    original_value = model.send(attribute)
    original_valid = model.valid?
    setter = :"#{attribute}="

    if message.is_a?(Hash)
      options = message.merge(options || {})
      message = nil
    end

    pre = options[:start].to_s
    post = options[:end].to_s
    len = max_length - pre.length - post.length

    # try with minimum valid length.
    value = pre + ('a' * len) + post
    model.send setter, value
    assert model.valid?, message ? (message + ": !(#{value.length})") : "Should allow a string of #{value.length} characters."

    # try with one extra character.
    value = pre + ('a' * (len - 1)) + post
    model.send setter, value
    assert_not model.valid?, message ? (message + ": (#{value.length})") : "Should not allow a string of #{value.length} characters."

    model.send setter, original_value
    if original_valid
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end
  end

  ##
  # Tests a specific field for uniqueness.
  #
  # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
  # The model will be saved to perform uniqueness testing.
  #
  # +attribute+ must provide the name of a valid attribute in the model.
  #
  # +case_sensitive+ determines if changing case should change validation.
  #
  # +message+ is optional, but if provided it will be postfixed with the failure reason.
  #
  # +alternate_scopes+ is also optional.  If provided the keys of the hash will be used to
  # set additional attributes on the model.  When these attributes are changed to the alternate
  # values, the model should once again be valid.
  def assert_uniqueness(model, attribute, case_sensitive = false, message = nil, alternate_scopes = {})
    setter = :"#{attribute}="
    original_value = model.send(attribute)

    if case_sensitive.is_a?(Hash)
      alternate_scopes = case_sensitive.merge(alternate_scopes || {})
      case_sensitive = false
    end
    if message.is_a?(Hash)
      alternate_scopes = message.merge(alternate_scopes || {})
      message = nil
    end

    copy = model.dup
    model.save!

    assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
    unless case_sensitive
      copy.send(setter, original_value.to_s.upcase)
      assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
      copy.send(setter, original_value.to_s.downcase)
      assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
    end

    unless alternate_scopes.blank?
      copy.send(setter, original_value)
      assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
      alternate_scopes.each do |k,v|
        kset = :"#{k}="
        vorig = copy.send(k)
        copy.send(kset, v)
        assert copy.valid?, message ? (message + ": !#{k}(#{v})") : "Duplicate model with #{k}=#{v.inspect} should be valid with #{attribute}=#{copy.send(attribute).inspect}."
        copy.send(kset, vorig)
        assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."      end
    end
  end

  ##
  # Tests access permissions for a specific action.
  #
  # Options:
  # * +controller+ is the string name of the controller.  If not supplied, the controller is inferred from the class name.
  # * +url_helper+ is a string to generate the url. If not supplied, the helper is inferred from the controller and action names.
  # * +fixture_helper+ is a string defining the fixture helper to use.  If not supplied the controller name will be used.
  # * +fixture_key+ is the fixture key to use.  Defaults to :one.
  # * +allow_anon+ determines if anonymous users should be able to access the action.  Default is false.
  # * +allow_any_user+ determines if any logged in user should be able to access the action.  Default is false.
  # * +allow_groups+ determines if a specific set of groups can access the action.  Default is nil.
  # * +deny_groups+ determines if a specific set of groups should not be able to access the action.  Default is nil.
  # * +allow_admin+ determines if system admins can access the action.  Default is true.
  # * +method+ determines the method to process the action with.  Default is 'get'.
  # * +success+ determines the result on success.  Defaults to :success for 'get' requests, otherwise the pluralized controller helper path.
  # * +failure+ determines the result on failure for non-anon tests.  Defaults to 'root_url'.
  # * +anon_failure+ determines the result on failure for anon tests.  Defaults to 'login_url'.
  #
  def self.access_tests_for(action, options = {})
    options = {
        allow_anon: false,
        allow_any_user: false,
        allow_groups: nil,
        allow_admin: true,
        fixture_key: :one,
        failure: 'root_url',
        anon_failure: 'login_url'
    }.merge(options || {})

    if action.respond_to?(:each)
      action.each do |act|
        access_tests_for(act, options.dup)
      end
      return
    end

    action = action.to_sym
    params = options[:"#{action}_params"]
    params = nil unless params.is_a?(Hash)

    if options[:method].blank?
      options[:method] =
          if action == :destroy
            'delete'
          elsif action == :update
            'patch'
          elsif action == :create
            'post'
          else
            'get'
          end
    end

    if options[:controller].blank?
      options[:controller] = self.name.underscore.rpartition('_')[0]
    else
      options[:controller] = options[:controller].to_s.underscore
    end

    if options[:controller][-11..-1] == '_controller'
      options[:controller] = options[:controller].rpartition('_')[0]
    end

    if options[:fixture_helper].blank?
      options[:fixture_helper] = options[:controller]
    end

    options[:method] = options[:method].to_sym

    if options[:url_helper].blank?
      fix_val = "#{options[:fixture_helper].pluralize}(#{options[:fixture_key].inspect})"
      options[:url_helper] =
          case action
            when :show, :update, :destroy   then  "#{options[:controller].singularize}_path(#{fix_val})"
            when :edit                      then  "edit_#{options[:controller].singularize}_path(#{fix_val})"
            when :new                       then  "new_#{options[:controller].singularize}_path"
            else                                  "#{options[:controller].pluralize}_path"
          end
    end

    if options[:success].blank?
      if options[:method] == :get
        options[:success] = :success
      else
        options[:success] = "#{options[:controller].pluralize}_path"
      end
    end


    method = options[:method]
    url_helper = options[:url_helper]

    tests = [
        [ 'anonymous', options[:allow_anon],      nil,      nil,    nil,    options[:anon_failure] ],
        [ 'any user',  options[:allow_any_user],  :basic ],
        [ 'admin user', options[:allow_admin],    :admin ]
    ]

    unless options[:allow_groups].blank?
      if options[:allow_groups].is_a?(String)
        options[:allow_groups] = options[:allow_groups].gsub(',', ';').split(';').map{|v| v.strip}
      end
      options[:allow_groups].each do |group|
        tests << [ "#{group} member", true, :basic, group ]
      end
    end

    unless options[:deny_groups].blank?
      if options[:deny_groups].is_a?(String)
        options[:deny_groups] = options[:deny_groups].gsub(',', ';').split(';').map{|v| v.strip}
      end
      options[:deny_groups].each do |group|
        tests << [ "#{group} member", false, :basic, group ]
      end
    end

    tests.each do |(label, result, user, group, success_override, failure_override)|
      expected_result = result ? (success_override || options[:success]) : (failure_override || options[:failure])

      test_code = "test \"should #{result ? '' : 'not '}allow access to #{action} for #{label}\" do\n"

      if user
        test_code += "user = users(#{user.inspect})\n"
        if group
          test_code += "group = AccessGroup.get(#{group.inspect}) || AccessGroup.create(name: #{group.inspect})\n"
          test_code += "user.groups << group\n"
        end
        test_code += "log_in_as user\n"
      end

      test_code += "path = #{url_helper}\n"

      if params.blank?
        test_code += "#{method} path\n"
      else
        test_code += "#{method} path, #{params.inspect[1...-1]}\n"
      end

      if expected_result.is_a?(Symbol)
        test_code += "assert_response #{expected_result.inspect}\n"
      else
        test_code += "assert_redirected_to #{expected_result}\n"
      end

      test_code += "end\n"

      eval test_code
    end

  end

  ##
  # Is a user currently logged in?
  def is_logged_in?
    !session[:user_id].nil?
  end

  ##
  # Logs in as the specified user.
  def log_in_as(user, options = {})
    password      = options[:password]      || 'password'
    remember_me   = options[:remember_me]   || '1'
    if integration_test?
      post login_path, session: { email: user.email, password: password, remember_me: remember_me }
    else
      session[:user_id] = user.id
    end
  end

  ##
  # Are we running an integration test?
  def integration_test?
    defined?(post_via_redirect)
  end

end


