# frozen_string_literal: true

module Casein
  class AdminUserSession < ::Authlogic::Session::Base
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    cookie_key 'casein_admin_user_credentials'
  end
end
