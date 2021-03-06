module Shield::EmailConfirmationSession
  macro included
    def verify!
      verify.not_nil!
    end

    def verify
      yield self, verify
    end

    def verify : EmailConfirmation?
      email_confirmation unless expired?
    end

    def expired? : Bool?
      email_confirmation.try &.expired?
    end

    def email_confirmation! : EmailConfirmation
      email_confirmation.not_nil!
    end

    def email_confirmation : EmailConfirmation?
      return unless email_confirmation_email &&
        email_confirmation_ip_address &&
        email_confirmation_started_at

      EmailConfirmation.new(
        email_confirmation_user_id,
        email_confirmation_email!,
        email_confirmation_ip_address!,
        email_confirmation_started_at!
      )
    end

    def email_confirmation_user! : User
      email_confirmation_user.not_nil!
    end

    def email_confirmation_user_id! : Int64
      email_confirmation_user_id.not_nil!
    end

    def email_confirmation_email! : String
      email_confirmation_email.not_nil!
    end

    def email_confirmation_ip_address! : String
      email_confirmation_ip_address.not_nil!
    end

    def email_confirmation_started_at! : Time
      email_confirmation_started_at.not_nil!
    end

    @[Memoize]
    def email_confirmation_user : User?
      email_confirmation_user_id.try { |id| UserQuery.new.id(id).first? }
    end

    def email_confirmation_user_id : Int64?
      @session.get?(:email_confirmation_user_id).try &.to_i64
    rescue
    end

    def email_confirmation_email : String?
      @session.get?(:email_confirmation_email)
    end

    def email_confirmation_ip_address : String?
      @session.get?(:email_confirmation_ip_address).try do |ip|
        Socket::IPAddress.new(ip, 0).address
      end
    rescue
    end

    def email_confirmation_started_at : Time?
      @session.get?(:email_confirmation_started_at).try do |time|
        Time.unix(time.to_i64)
      end
    rescue
    end

    def delete : self
      @session.delete(:email_confirmation_user_id)
      @session.delete(:email_confirmation_email)
      @session.delete(:email_confirmation_ip_address)
      @session.delete(:email_confirmation_started_at)
      self
    end

    def set(token : String) : self
      CryptoHelper.verify_and_decrypt(token).try do |token|
        set(token[0]?, token[1]?, token[2]?, token[3]?)
      end

      self
    end

    def set(email_confirmation : EmailConfirmation) : self
      set(
        email_confirmation.user_id,
        email_confirmation.email,
        email_confirmation.ip_address,
        email_confirmation.started_at
      )
    end

    def set(user_id, email, ip_address, started_at : Time) : self
      set(user_id, email, ip_address, started_at.to_unix)
    end

    def set(user_id, email, ip_address, started_at) : self
      @session.set(:email_confirmation_user_id, user_id.to_s)
      @session.set(:email_confirmation_email, email.to_s)
      @session.set(:email_confirmation_ip_address, ip_address.to_s)
      @session.set(:email_confirmation_started_at, started_at.to_s)
      self
    end
  end
end
