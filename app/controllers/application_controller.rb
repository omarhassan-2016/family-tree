class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_login
  before_action :set_locale
  helper_method :current_user

  private

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    # Redirect to first run setup if no users exist
    if User.count == 0
      redirect_to setup_path unless controller_name == "setup"
      return
    end

    unless current_user
      redirect_to login_path, alert: "Please log in to access the Family Tree."
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "You do not have permission to perform this action."
    end
  end

  def require_contributor
    unless current_user&.admin? || current_user&.contributor?
      redirect_to root_path, alert: "You do not have permission to edit the tree."
    end
  end
end
