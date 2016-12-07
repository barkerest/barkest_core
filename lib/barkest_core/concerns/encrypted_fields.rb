require 'encrypted_strings'

module BarkestCore

  ##
  # Adds helper methods to the model to allow easy manipulation of fields stored as encrypted values.
  #
  # The encryption password is specified in +secrets.yml+.
  #
  # For a class MyNamespace::MyClass you can specify the encryption password using +my_namespace_my_class+
  # or +my_class+ keys in the appropriate section of +secrets.yml+.
  #
  # If no specific encryption password is provided, then +secret_key_base+ is used instead.
  #
  module EncryptedFields

    # :nodoc:
    def self.included(base)
      base.class_eval do

        private

        def self.crypto_password
          @crypto_password ||=
              begin
                klass = self.class.name.to_s.underscore
                if klass.include?('/')
                  Rails.application.secrets[klass.gsub('/','_').to_sym] ||
                      Rails.application.secrets[klass.rpartition('/')[2].to_sym] ||
                      Rails.application.secrets[:secret_key_base]
                else
                  Rails.application.secrets[klass.to_sym] ||
                      Rails.application.secrets[:secret_key_base]
                end
              end
        end

        def self.crypto_cipher
          @crypto_cipher ||= EncryptedStrings::SymmetricCipher.new(password: crypto_password)
        end

        def self.decrypt_value(value)
          return nil if value.nil?
          return '' if value == ''
          crypto_cipher.decrypt(value)
        end

        public

        ##
        # Encrypts a value using this model's key.
        #
        # Will not encrypt nil or empty strings.
        def self.encrypt_value(value)
          return nil if value.nil?
          return '' if value == ''
          crypto_cipher.encrypt(value)
        end

        protected

        ##
        # Defines methods to allow accessing an encrypted field easily.
        #
        # Simplest usage:
        #   encrypted_field :encrypted_field_name
        #
        # Detailed usage:
        #   encrypted_field :encrypted => :encrypted_field_name,
        #       :decrypted => :field_name,
        #       :read_only => false
        #
        # In both usages, the model will receive two new methods:
        #   def field_name
        #     ...
        #   end
        #
        #   def field_name=(value)
        #     ...
        #   end
        #
        # If you specify :read_only => true, then only one method will be defined:
        #   def field_name
        #     ...
        #   end
        #
        # Raises a StandardError if the attribute names cannot be determined or if the
        # encrypted attribute is not defined.
        #
        def self.encrypted_field(options = {})
          unless options.is_a?(Hash)
            attr_name = options.to_s
            if attr_name[0...10] == 'encrypted_' ||
                attr_name[0...4] == 'enc_' ||
                attr_name[-4..-1] == '_enc' ||
                attr_name[-10..-1] == '_encrypted'
              options = {
                  encrypted: attr_name
              }
            else
              options = {
                  decrypted: attr_name
              }
            end
          end

          raise StandardError.new('Options must contain either :decrypted or :encrypted key.') if options[:encrypted].blank? && options[:decrypted].blank?

          if options[:encrypted].blank?
            attr_name = options[:decrypted]
            %W(encrypted_#{attr_name} enc_#{attr_name} #{attr_name}_enc #{attr_name}_encrypted).each do |attr|
              if method_defined?(attr) || columns.find{|a| a.name == attr}
                options[:encrypted] = attr
              end
            end
          elsif options[:decrypted].blank?
            attr_name = options[:encrypted]
            if attr_name[0...10] == 'encrypted_' || attr_name[0...4] == 'enc_'
              options[:decrypted] = attr_name.partition('_')[2]
            elsif attr_name[-4..-1] == '_enc' || attr_name[-10..-1] == '_encrypted'
              options[:decrypted] = attr_name.rpartition('_')[0]
            end
          end

          raise StandardError.new("Cannot locate encrypted attribute with #{options[:decrypted]} as the decypted attribute name.") if options[:encrypted].blank?
          raise StandardError.new("Cannot determine decrypted attribute name with #{options[:encrypted]} as the encrypted attribute.") if options[:decrypted].blank?

          define_method options[:decrypted].to_sym do
            self.class.decrypt_value send(options[:encrypted])
          end

          unless options[:read_only]
            define_method :"#{options[:decrypted]}=" do |value|
              send "#{options[:encrypted]}=", self.class.encrypt_value(value)
            end
          end

        end

        ##
        # Encrypts a value and returns the result in base64 encoding.
        def encrypt(value)
          self.class.encrypt_value(value)
        end

        ##
        # Decodes a base64 value and returns the decrypted value.
        def decrypt(value)
          self.class.decrypt_value(value)
        end

      end
    end

  end
end