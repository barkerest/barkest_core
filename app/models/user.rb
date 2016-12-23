##
# The user class defines the individual users in the application.
#
# Each user can login with their email address, if the domain portion of their
# email address happens to match an LdapSource, then that LdapSource will be
# used to authenticate them, otherwise the +password_digest+ stored in the
# database will be used to authenticate them.
class User < ::BarkestCore::DbTable

  ANONYMOUS_EMAIL = 'anonymous@local.server'

  UNIQUE_STRING_FIELD = :email
  include BarkestCore::NamedModel
  include BarkestCore::EmailTester

  has_many :access_group_user_members, class_name: 'AccessGroupUserMember', foreign_key: 'member_id'
  private :access_group_user_members, :access_group_user_members=

  has_many :groups, class_name: 'AccessGroup', through: :access_group_user_members

  has_many :login_histories, :class_name => 'UserLoginHistory'

  belongs_to :disabled_by, class_name: 'User'

  before_save :downcase_email
  before_create :create_activation_digest

  ##
  # Gets the temporary token used to remember this user.
  attr_accessor :remember_token

  ##
  # Gets the temporary token used to activate this user.
  attr_accessor :activation_token

  ##
  # Gets the temporary token used to reset this user's password.
  attr_accessor :reset_token

  has_secure_password

  validates :name,
            presence: true,
            length: { maximum: 100 }

  validates :email,
            presence: true,
            length: { maximum: 255 },
            uniqueness: { case_sensitive: false },
            format: { with: VALID_EMAIL_REGEX }

  validates :disabled_reason,
            length: { maximum: 200 }

  validates :last_ip,
            length: { maximum: 64 }

  validates :password,
            presence: true,
            length: { minimum: 6 },
            allow_nil: true


  ##
  # Gets the email address in a partially obfuscated fashion.
  def partial_email
    uid,_,domain = email.partition('@')
    if uid.length < 4
      uid = '*' * uid.length
    elsif uid.length < 8
      uid = uid[0..2] + ('*' * (uid.length - 3))
    else
      uid = uid[0..2] + ('*' * (uid.length - 6)) + uid[-3..-1]
    end
    "#{uid}@#{domain}"
  end

  ##
  # Is the user a system administrator?
  def system_admin?
    enabled && system_admin
  end

  ##
  # Gets the effective group membership of this user.
  def effective_groups(refresh = false)
    @effective_groups = nil if refresh
    @effective_groups ||= if system_admin?
                          AccessGroup.all.map{ |g| g.to_s.upcase }
                        else
                          groups
                              .collect{ |g| g.effective_groups }
                              .flatten
                              .inject([]){ |memo,item| memo << item unless memo.include?(item); memo }
                        end
                            .map{ |g| g.to_s.upcase }
                            .sort
  end

  ##
  # Does this user have the equivalent of one or more of these groups?
  def has_any_group?(*group_list)
    return true if system_admin?

    group_list.each do |group|
      group = group.to_s.upcase
      return true if effective_groups.include?(group)
    end

    false
  end

  ##
  # Generates a remember token and saves the digest to the user model.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(self.remember_token))
  end

  ##
  # Removes the remember digest from the user model.
  def forget
    update_attribute(:remember_digest, nil)
  end

  ##
  # Determines if the supplied token digests to the stored digest in the user model.
  def authenticated?(attribute, token)
    return false unless respond_to?("#{attribute}_digest")
    digest = send("#{attribute}_digest")
    return false if digest.blank?
    BCrypt::Password.new(digest).is_password?(token)
  end

  ##
  # Disables the user.
  #
  # The +other_user+ is required, cannot be the current user, and must be a system administrator.
  # The +reason+ is technically optional, but should be provided.
  def disable(other_user, reason)
    return false unless other_user && other_user.system_admin?
    return false if other_user == self

    update_columns(
        disabled_by_id: other_user.id,
        disabled_at: Time.zone.now,
        disabled_reason: reason,
        enabled: false
    )
  end

  ##
  # Enables the user and removes any previous disable information.
  def enable
    update_columns(
        disabled_by_id: nil,
        disabled_at: nil,
        disabled_reason: nil,
        enabled: true
    )
  end


  ##
  # Marks the user as activated and removes the activation digest from the user model.
  def activate
    update_columns(
        activated: true,
        activated_at: Time.zone.now,
        activation_digest: nil
    )
  end

  ##
  # Sends the activation email to the user.
  def send_activation_email(client_ip = '0.0.0.0')
    BarkestCore::UserMailer.account_activation(user: self, client_ip: client_ip).deliver_now
  end

  ##
  # Creates a reset token and stores the digest to the user model.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(
        reset_digest: User.digest(reset_token),
        reset_sent_at: Time.zone.now
    )
  end

  ##
  # Was the password reset requested more than 2 hours ago?
  def password_reset_expired?
    reset_sent_at.nil? || reset_sent_at < 2.hours.ago
  end

  ##
  # Is this the anonymous user?
  def anonymous?
    email == ANONYMOUS_EMAIL
  end

  ##
  # Gets the last successful login for this user.
  def last_successful_login
    @last_successful_login ||= login_histories.where(successful: true).order(created_at: :desc).first
  end

  ##
  # Gets the last failed login for this user.
  def last_failed_login
    @last_failed_login ||= login_histories.where.not(successful: true).order(created_at: :desc).first
  end

  ##
  # Gets the failed logins for a user since the last successful login.
  def failed_login_streak
    @failed_login_streak ||=
        begin
          results = login_histories.where.not(successful: true)
          if last_successful_login
            results = results.where('created_at > ?', last_successful_login.created_at)
          end
          results.order(created_at: :desc)
        end
  end

  def settings(reload = false)
    @settings = nil if reload
    @settings ||=
        begin
          h = SystemConfig.get("user_#{id}") || {}
          h.instance_variable_set :@user_id, id

          def h.save
            SystemConfig.set "user_#{@user_id}", self
          end

          def h.method_missing(m,*a,&b)
            x = (/^([A-Z][A-Z0-9_]*)(=)?$/i).match(m.to_s)
            if x
              key = x[1].to_sym
              if x[2] == '='
                val = a ? a.first : nil
                self[key] = val
                return val
              else
                return self[key]
              end
            end
            super m, *a, &b
          end

          def h.[](key)
            super key.to_sym
          end

          def h.[]=(key, value)
            super key.to_sym, value
          end

          h
        end
  end

  ##
  # Sends the password reset email to the user.
  def send_password_reset_email(client_ip = '0.0.0.0')
    BarkestCore::UserMailer.password_reset(user: self, client_ip: client_ip).deliver_now
  end

  ##
  # Sends a missing account message when a user requests a password reset.
  def self.send_missing_reset_email(email, client_ip = '0.0.0.0')
    BarkestCore::UserMailer::invalid_password_reset(email: email, client_ip: client_ip).deliver_now
  end

  ##
  # Sends a disabled account message when a user requests a password reset.
  def self.send_disabled_reset_email(email, client_ip = '0.0.0.0')
    BarkestCore::UserMailer::invalid_password_reset(email: email, message: 'The account attached to this email address has been disabled.', client_ip: client_ip).deliver_now
  end

  ##
  # Sends a non-activated account message when a user requests a password reset.
  def self.send_inactive_reset_email(email, client_ip = '0.0.0.0')
    BarkestCore::UserMailer::invalid_password_reset(email: email, message: 'The account attached to this email has not yet been activated.', client_ip: client_ip).deliver_now
  end

  ##
  # Sends a message informing the user we cannot change LDAP passwords.
  def self.send_ldap_reset_email(email, client_ip = '0.0.0.0')
    BarkestCore::UserMailer::invalid_password_reset(email: email, message: 'The account attached to this email is an LDAP account.  This application cannot change passwords on an LDAP account.', client_ip: client_ip).deliver_now
  end

  ##
  # Returns a hash digest of the given string.
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  ##
  # Generates a new random token in (url safe) base64.
  def self.new_token
    SecureRandom.urlsafe_base64(32)
  end

  ##
  # Gets all known users.
  def self.known
    where.not(email: ANONYMOUS_EMAIL)
  end

  ##
  # Gets all of the currently enabled users.
  def self.enabled
    where(enabled: true, activated: true)
  end

  ##
  # Sorts the users by name.
  def self.sorted
    order(name: :asc)
  end

  ##
  # Generates the necessary system administrator account.
  #
  # When the database is initially seeded, the only user is the system administrator.
  # The system administrator is **admin@barkerest.com** and the password is initially **Password1**.
  # You should change this immediately once the app is running.  You will most likely want to create
  # a completely new admin account and disable the **admin@barkerest.com** account.
  def self.ensure_admin_exists!
    unless where(system_admin: true, enabled: true).count > 0

      msg = "Creating/reactivating default administrator...\n"
      if Rails.application.running?
        Rails.logger.info msg
      else
        print msg
      end

      def_adm_email = 'admin@barkerest.com'
      def_adm_pass = 'Password1'

      user = User
                 .where(
                     email: def_adm_email
                 )
                 .first_or_create!(
                     name: 'Default Administrator',
                     email: def_adm_email,
                     password: def_adm_pass,
                     password_confirmation: def_adm_pass,
                     enabled: true,
                     system_admin: true,
                     activated: true,
                     activated_at: Time.zone.now
                 )

      unless user.enabled? && user.system_admin?
        user.password = def_adm_pass
        user.password_confirmation = def_adm_pass
        user.enabled = true
        user.system_admin = true
        user.activated = true
        user.activated_at = Time.zone.now
        user.save!
      end
    end
  end

  ##
  # Gets a generic anonymous user.
  def self.anonymous
    @anonymous = nil if Rails.env.test?
    @anonymous ||=
        begin
          pwd = new_token
          where(email: ANONYMOUS_EMAIL)
              .first_or_create(
                  email: ANONYMOUS_EMAIL,
                  name: 'Anonymous',
                  enabled: false,
                  activated: true,
                  activated_at: Time.zone.now,
                  password: pwd,
                  password_confirmation: pwd
              )
        end
  end


  private

  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

end
