module Gemgento

  # @author Gemgento LLC
  class Session < ActiveRecord::Base

    def self.get(client, force_new_session)
      if Session.last.nil? || Session.last.expired || force_new_session
        response = client.call(:login, message: { username: Config[:magento][:username], apiKey: Config[:magento][:api_key] })

        unless response.success?
          puts 'Login Failed - Check Session'
          exit # cannot recover from this
        end

        session = response.body[:login_response][:login_return];

        s = Session.new
        s.session_id = session
        s.save
      else
        s = Session.last
        s.touch

        session = s.session_id
      end

      return session
    end

    def expired
      if self.updated_at <= timeout.seconds.ago
        return true
      else
        return false
      end
    end

    private

    def timeout
      if Config[:magento][:session_life].nil?
        return 24 * 60 # default of 24 minutes, determined by PHP
      else
        return Config[:magento][:session_life].to_i
      end
    end

  end
end