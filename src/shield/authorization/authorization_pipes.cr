module Shield::AuthorizationPipes
  macro included
    def require_authorization
      if @authorized
        continue
      else
        raise Shield::NoAuthorizationError.new(
          "Authorization not performed for '#{self.class}' action"
        )
      end
    end
  end
end
