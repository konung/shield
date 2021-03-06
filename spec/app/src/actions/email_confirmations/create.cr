class EmailConfirmations::Create < ApiAction
  include Shield::EmailConfirmations::Create

  post "/email-confirmations" do
    run_operation
  end

  def do_run_operation_succeeded(operation, email_confirmation)
    json({status: 0})
  end

  def do_run_operation_failed(operation)
    json({status: 1})
  end
end
