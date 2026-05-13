class LocalesController < ApplicationController
  skip_before_action :require_login

  def update
    locale = params[:locale].to_s.strip.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
    end
    
    # Redirect back to where the user came from, or root if unknown
    redirect_back fallback_location: root_path
  end
end
