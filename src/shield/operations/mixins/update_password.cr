
module Shield::UpdatePassword
  macro included
    include Shield::ValidatePassword

    needs current_login : Login?

    after_save log_out_everywhere

    after_commit notify_password_change

    before_save do
      set_password_digest
    end

    private def set_password_digest
      password.value.try do |value|
        return if CryptoHelper.verify_bcrypt?(
          value,
          password_digest.original_value.to_s
        )

        password_digest.value = CryptoHelper.hash_bcrypt(value)
      end
    end

    private def log_out_everywhere(user : User)
      return unless password_digest.changed?

      LoginQuery.new
        .status(Login::Status.new :started)
        .id.not.eq(current_login.try(&.id) || 0_i64)
        .update(ended_at: Time.utc, status: Login::Status.new(:ended))
    end

    private def notify_password_change(user : User)
      return unless password_digest.changed?
      return unless user.options!.password_notify

      mail_later PasswordChangeNotificationEmail, self, user
    end
  end
end
