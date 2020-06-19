module Shield::DestroyLogin
  macro included
    # delete "/log-out" do
    #   log_user_out
    # end

    private def log_user_out
      LogUserOut.update(
        Login.from_session!(session),
        session: session,
        cookies: cookies
      ) do |operation, updated_login|
        if operation.saved?
          success_action(operation, updated_login)
        else
          failure_action(operation, updated_login)
        end
      end
    end

    private def success_action(operation, updated_login)
      flash.info = "Logged out. See ya!"
      redirect to: New
    end

    private def failure_action(operation, updated_login)
      flash.failure = "Something went wrong"
      redirect to: CurrentUser::Show
    end
  end
end
