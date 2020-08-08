abstract class ApiAction < Lucky::Action
  include Shield::Action

  accepted_formats [:json]

  private def require_logged_in_action
    json({logged_in: false})
  end

  private def require_logged_out_action
    json({logged_in: true})
  end

  def not_authorized_action
    json({authorized: false})
  end

  def authorize? : Bool
    current_user!.level.admin?
  end
end
