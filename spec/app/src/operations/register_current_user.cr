require "./save_user_options"

class RegisterCurrentUser < User::SaveOperation
  include Shield::RegisterUser

  before_save set_level

  private def set_level
    level.value = User::Level.new(:author)
  end
end
