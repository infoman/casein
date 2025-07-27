# frozen_string_literal: true

require 'authlogic'

module Casein
  class CaseinController < ApplicationController
    helper Casein::CaseinHelper
    helper Casein::ConfigHelper

    layout 'casein_main'

    helper_method :current_admin_user_session, :current_user
    before_action :authorise
    before_action :set_time_zone

    ActionView::Base.field_error_proc = proc { |input, _instance| input.to_s.html_safe }

    def index
      redirect_to casein_config_dashboard_url
    end

    def blank
      @casein_page_title = 'Welcome'
    end

    private

    def authorise
      unless current_user
        session[:return_to] = request.fullpath
        redirect_to new_casein_admin_user_session_url
        false
      end
    end

    def set_time_zone
      Time.zone = current_user.time_zone if current_user
    end

    def current_admin_user_session
      return @current_admin_user_session if defined?(@current_admin_user_session)

      @current_admin_user_session = Casein::AdminUserSession.find
    end

    def current_user
      return @session_user if defined?(@session_user)

      @session_user = current_admin_user_session&.admin_user
    end

    def needs_admin
      unless @session_user.is_admin?
        redirect_to controller: :casein, action: :index
      end
    end

    def needs_admin_or_current_user
      unless @session_user.is_admin? || params[:id].to_i == @session_user.id
        redirect_to controller: :casein, action: :index
      end
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def sort_order(default)
      column = (params[:c] || default.to_s).gsub(/[\s;'\"]/, '')
      direction = params[:d] == 'down' ? 'DESC' : 'ASC'
      { column => direction }
    end
  end
end
