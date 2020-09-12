class PasswordResetRequestEmail < BaseEmail
  def initialize(
    @operation : StartPasswordReset,
    @password_reset : PasswordReset
  ) : Nil
  end

  private def receivers
    @password_reset.user!
  end

  private def heading
    "Reset your password"
  end

  private def text_message : String
    <<-TEXT
    #{PasswordResetHelper.password_reset_url(@password_reset, @operation)}
    TEXT
  end
end