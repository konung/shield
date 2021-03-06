module Shield::EmailConfirmations::Update
  # IMPORTANT!
  #
  # This requires the user to be logged in to update their email address.
  # The current user's ID is compared with the `user_id` retrieved from session
  # to ensure they match, before updating the email.
  #
  # This prevents problems when an existing user mistypes their new email
  # address, and the confirmation link gets sent to this wrong address.
  #
  # The new email address owner could click to confirm the email,
  # thus changing the user's email address to theirs. After that, they could
  # request for a password reset, locking the legitimate user out of their
  # account.
  macro included
    skip :require_logged_out

    before :pin_email_confirmation_to_ip_address

    # patch "/email-confirmations" do
    #   run_operation
    # end

    def run_operation
      EmailConfirmationSession.new(
        session
      ).verify do |utility, email_confirmation|
        if email_confirmation.try &.user_id == current_user!.id # <= IMPORTANT!
          update_email(email_confirmation.not_nil!)
        else
          CurrentUser::New.new(
            context,
            Hash(String, String).new
          ).do_run_operation_failed(utility)
        end
      end
    end

    private def update_email(email_confirmation)
      UpdateConfirmedEmail.update(
        email_confirmation.user!,
        email: email_confirmation.email,
        session: session
      ) do |operation, updated_user|
        if operation.saved?
          do_run_operation_succeeded(operation, updated_user)
        else
          do_run_operation_failed(operation, updated_user)
        end
      end
    end

    def do_run_operation_succeeded(operation, user)
      flash.success = "Email changed successfully"
      redirect to: CurrentUser::Show
    end

    def do_run_operation_failed(operation, user)
      flash.failure = "Could not change email"
      html EditPage, operation: operation, user: user
    end

    def authorize? : Bool
      true
    end
  end
end
