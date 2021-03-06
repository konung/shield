module Shield::PasswordResets::Create
  macro included
    skip :require_logged_in

    # post "/password-resets" do
    #   run_operation
    # end

    def run_operation
      StartPasswordReset.create(
        params,
        remote_ip: remote_ip
      ) do |operation, password_reset|
        if password_reset
          do_run_operation_succeeded(operation, password_reset.not_nil!)
        else
          do_run_operation_failed(operation)
        end
      end
    end

    def do_run_operation_succeeded(operation, password_reset)
      success_action
    end

    def do_run_operation_failed(operation)
      if operation.guest_email?
        success_action
      else
        flash.failure = "Password reset request failed"
        html NewPage, operation: operation
      end
    end

    private def success_action
      flash.success = "Done! Check your email for further instructions."
      redirect to: Logins::New
    end
  end
end
