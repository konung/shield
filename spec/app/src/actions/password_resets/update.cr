class PasswordResets::Update < ApiAction
  include Shield::PasswordResets::Update

  patch "/password-resets" do
    reset_password
  end

  private def success_action(operation, user)
    json({a: ""})
  end

  private def failure_action(operation, user)
    json({a: ""})
  end
end
