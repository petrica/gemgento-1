module Gemgento
  class User::PasswordsController < Devise::PasswordsController

    protected

    # The path used after sending reset password instructions
    def after_sending_reset_password_instructions_path_for(resource_name)
      if is_navigational_format?
        if Config[:combined_shipping_payment]
          user_new_login_path
        else
          new_session_path(resource_name)
        end
      end
    end

  end
end