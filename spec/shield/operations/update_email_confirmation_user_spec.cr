require "../../spec_helper"

describe Shield::UpdateEmailConfirmationUser do
  it "does not update email" do
    email = "user@example.tld"
    new_email = "user@domain.com"

    user = create_current_user!(email: email)

    UpdateEmailConfirmationCurrentUser.update(
      user,
      params(email: new_email),
      current_login: nil,
      remote_ip: Socket::IPAddress.new("129.0.0.3", 5555)
    ) do |operation, updated_user|
      operation.saved?.should be_true

      operation.new_email.should eq(new_email)
      updated_user.email.should eq(email)
    end
  end

  it "updates user options" do
    user = create_current_user!(
      login_notify: true,
      password_notify: false
    )

    UpdateEmailConfirmationCurrentUser.update(
      user,
      params(login_notify: "false", password_notify: "true"),
      current_login: nil,
      remote_ip: Socket::IPAddress.new("129.0.0.3", 5555)
    ) do |operation, updated_user|
      operation.saved?.should be_true

      user_options = updated_user.options!
      user_options.login_notify.should be_false
      user_options.password_notify.should be_true
    end
  end

  it "fails when nested operation fails" do
    user = create_current_user!(login_notify: true, password_notify: true)

    UpdateEmailConfirmationCurrentUser2.update(
      user,
      params(login_notify: false, password_notify: false),
      current_login: nil,
      remote_ip: Socket::IPAddress.new("129.0.0.3", 5555)
    ) do |operation, updated_user|
      operation.saved?.should be_false

      user_options = updated_user.options!
      user_options.login_notify.should be_true
      user_options.password_notify.should be_true
    end
  end

  it "fails when attributes change and nested operation fails" do
    password = "password12U-password"
    new_password = "assword12U-passwor"

    user = create_current_user!(
      password: password,
      password_confirmation: password,
      login_notify: true,
      password_notify: true
    )

    UpdateEmailConfirmationCurrentUser2.update(
      user,
      params(
        password: new_password,
        password_confirmation: new_password,
        login_notify: false,
        password_notify: false
      ),
      current_login: nil,
      remote_ip: Socket::IPAddress.new("129.0.0.3", 5555)
    ) do |operation, updated_user|
      operation.saved?.should be_false

      user_options = updated_user.options!
      user_options.login_notify.should be_true
      user_options.password_notify.should be_true
    end
  end
end
