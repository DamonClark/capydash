require 'securerandom'
require 'digest'

module CapyDash
  class Auth
    class << self
      def authenticate(username, password)
        return false unless auth_enabled?

        # Simple hardcoded credentials for MVP
        # In production, this would connect to a proper user database
        valid_credentials = {
          'admin' => 'capydash123',
          'developer' => 'test123',
          'viewer' => 'readonly123'
        }

        if valid_credentials[username] == password
          token = generate_token(username)
          Logger.info("User authenticated", {
            username: username,
            token: token[0..8] + "..."
          })
          token
        else
          Logger.warn("Authentication failed", {
            username: username,
            ip: current_ip
          })
          nil
        end
      end

      def validate_token(token)
        return false unless auth_enabled?
        return false unless token && token.length > 10

        # Simple token validation for MVP
        # In production, this would use JWT or similar
        begin
          decoded = Base64.decode64(token)
          parts = decoded.split(':')
          return false unless parts.length == 3

          username, timestamp, signature = parts
          expected_signature = generate_signature(username, timestamp)

          if signature == expected_signature
            # Check if token is not expired (24 hours)
            token_time = Time.at(timestamp.to_i)
            if Time.now - token_time < 24 * 60 * 60
              Logger.debug("Token validated", { username: username })
              username
            else
              Logger.warn("Token expired", { username: username })
              false
            end
          else
            Logger.warn("Invalid token signature", { token: token[0..8] + "..." })
            false
          end
        rescue => e
          ErrorHandler.handle_error(e, {
            error_type: 'authentication',
            operation: 'validate_token'
          })
          false
        end
      end

      def auth_enabled?
        CapyDash.config.auth_enabled?
      end

      def require_auth!
        return true unless auth_enabled?
        # This would be called by middleware or controllers
        # For now, just return true
        true
      end

      private

      def generate_token(username)
        timestamp = Time.now.to_i.to_s
        signature = generate_signature(username, timestamp)
        token_data = "#{username}:#{timestamp}:#{signature}"
        Base64.encode64(token_data).strip
      end

      def generate_signature(username, timestamp)
        secret = CapyDash.config.secret_key
        data = "#{username}:#{timestamp}:#{secret}"
        Digest::SHA256.hexdigest(data)
      end

      def current_ip
        # In a real app, this would get the actual IP
        "127.0.0.1"
      end
    end
  end
end
