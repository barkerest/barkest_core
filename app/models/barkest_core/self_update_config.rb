module BarkestCore
  class SelfUpdateConfig
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :host, :port, :user, :password

    validates :host, presence: true
    validates :port, presence: true
    validates :user, presence: true

    def to_h
      {
          host: host.to_s,
          port: port.to_s.to_i,
          user: user.to_s,
          password: password.to_s,
      }
    end

    def save
      SystemConfig.set :self_update, to_h, true
    end

    def SelfUpdateConfig.load
      SelfUpdateConfig.new SystemConfig.get(:self_update)
    end

  end
end
