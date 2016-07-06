module BarkestCore
  # Preview all emails at http://localhost:3000/rails/mailers/barkest_core/user_mailer
  class UserMailerPreview < ActionMailer::Preview

    # Preview this email at http://localhost:3000/rails/mailers/barkest_core/user_mailer/account_activation
    def account_activation
      user = User.first
      user.activation_token = User.new_token
      UserMailer.account_activation user: user
    end

    # Preview this email at http://localhost:3000/rails/mailers/barkest_core/user_mailer/password_reset
    def password_reset
      user = User.first
      user.reset_token = User.new_token
      UserMailer.password_reset user: user
    end

    # Preview this email at http://localhost:3000/rails/mailers/barkest_core/user_mailer/invalid_password_reset
    def invalid_password_reset
      email = 'nobody@example.com'
      UserMailer.invalid_password_reset email: email
    end

  end
end
