# frozen_string_literal: true

include Casein::ConfigHelper

$CASEIN_USER_ACCESS_LEVEL_ADMIN = 0
$CASEIN_USER_ACCESS_LEVEL_USER = 10

module Casein
  class AdminUser < ActiveRecord::Base
    def self.table_name
      to_s.gsub('::', '_').tableize
    end

    acts_as_authentic do |c|
      c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
      c.crypto_provider = Authlogic::CryptoProviders::SCrypt
    end

    attr_accessor :notify_of_new_password

    after_create :send_create_notification
    after_update :send_update_notification
    before_validation :check_time_zone

    validates_presence_of :login, :name, :email
    validates_uniqueness_of :login, case_sensitive: false
    validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
    validates_presence_of :time_zone

    # These default validations come from authlogic:
    # https://github.com/binarylogic/authlogic/blob/master/doc/use_normal_rails_validation.md
    # Note that Casein uses a case-sensitive uniqueness validation for :login, so we remove that config
    validates :login,
              format: {
                with: /\A[a-zA-Z0-9_][a-zA-Z0-9\.+\-_@ ]+\z/,
                message: proc {
                  ::Authlogic::I18n.t(
                    'error_messages.login_invalid',
                    default: 'should use only letters, numbers, spaces, and .-_@+ please.'
                  )
                }
              },
              length: { within: 3..100 }

    validates :password,
              confirmation: { if: :require_password? },
              length: {
                minimum: 8,
                if: :require_password?
              }
    validates :password_confirmation,
              length: {
                minimum: 8,
                if: :require_password?
              }

    def self.has_more_than_one_admin
      Casein::AdminUser.where(access_level: $CASEIN_USER_ACCESS_LEVEL_ADMIN).count > 1
    end

    def send_create_notification
      Casein::CaseinNotification.new_user_information(casein_config_email_from_address, self, casein_config_hostname, @password).deliver
    end

    def send_update_notification
      if notify_of_new_password
        notify_of_new_password = false
        Casein::CaseinNotification.generate_new_password(casein_config_email_from_address, self, casein_config_hostname, @password).deliver
      end
    end

    def send_password_reset_instructions
      reset_perishable_token!
      Casein::CaseinNotification.password_reset_instructions(casein_config_email_from_address, self, casein_config_hostname).deliver
    end

    def check_time_zone
      self.time_zone = Rails.configuration.time_zone unless time_zone
    end

    def is_admin?
      access_level == $CASEIN_USER_ACCESS_LEVEL_ADMIN
    end
  end
end
