require "../../spec_helper"

describe Shield::SaveUser do
  it "saves new user" do
    password = "password12U password"

    create_user(
      email: "user@example.tld",
      password: password,
      password_confirmation: password,
      level: User::Level.new(:editor)
    ) do |operation, user|
      user.should be_a(User)
    end
  end

  it "updates existing user" do
    new_email = "newuser@example.tld"
    user = create_user!(email: "user@example.tld")

    SaveUser.update(
      user,
      email: new_email,
      current_login: nil
    ) do |operation, updated_user|
      operation.saved?.should be_true
      updated_user.email.should eq(new_email)
    end
  end

  it "saves user options" do
    user = create_user!(login_notify: true, password_notify: false)

    user_options = user.options!

    user_options.login_notify.should be_true
    user_options.password_notify.should be_false
  end

  it "updates user options" do
    user = create_user!(login_notify: true, password_notify: false)

    params = Avram::Params.new({
      "login_notify" => "false",
      "password_notify" => "true"
    })

    SaveUser.update(
      user,
      params,
      current_login: nil
    ) do |operation, updated_user|
      user_options = updated_user.options!

      user_options.login_notify.should be_false
      user_options.password_notify.should be_true
    end
  end
end
