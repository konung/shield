module Shield::EmailConfirmations::Create
  macro included
    skip :require_logged_in

    # post "/email-confirmations" do
    #   run_operation
    # end

    def run_operation
      StartEmailConfirmation.submit(
        params,
        remote_ip: remote_ip
      ) do |operation, email_confirmation|
        if email_confirmation
          do_run_operation_succeeded(operation, email_confirmation.not_nil!)
        else
          do_run_operation_failed(operation)
        end
      end
    end

    def do_run_operation_succeeded(operation, email_confirmation)
      success_action
    end

    def do_run_operation_failed(operation)
      if operation.user_email?
        success_action
      else
        flash.failure = "Email confirmation request failed"
        html NewPage, operation: operation
      end
    end

    private def success_action
      flash.success = "Done! Check your email for further instructions."
      redirect to: Logins::New
    end
  end
end
