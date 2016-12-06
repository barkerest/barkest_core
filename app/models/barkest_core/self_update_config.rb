module BarkestCore
  class SelfUpdateConfig
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :host, :port, :user, :password

    validates :host, presence: true
    validates :user, presence: true
    validates :password, presence: true

    def to_h
      {
          host: host.to_s,
          port: port,
          user: user.to_s,
          password: password.to_s,
      }
    end

    def port
      val = @port || 22
      val = val.to_s.to_i
      (1...65536).include?(val) ? val : 22
    end

    def save
      SystemConfig.set :self_update, to_h, true
    end

    def SelfUpdateConfig.load
      SelfUpdateConfig.new SystemConfig.get(:self_update)
    end

  end
end
