class UserLoginHistory < ::BarkestCore::DbTable

  belongs_to :user

  validates :user, presence: true
  validates :ip_address, presence: true, length: { maximum: 64 }
  validates :message, length: { maximum: 200 }

end
