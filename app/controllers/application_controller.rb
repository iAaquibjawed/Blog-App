class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, except: [:index] # Allow home#index without auth

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:name, :email, :password) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:name, :email, :password, :current_password) }
  end

  # Redirect after sign in
  def after_sign_in_path_for(resource)
    root_path # Dashboard
  end

  # Redirect after sign up
  def after_sign_up_path_for(resource)
    root_path # Dashboard
  end

  # Redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path # Landing page
  end
end