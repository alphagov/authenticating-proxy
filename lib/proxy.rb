require 'rack/proxy'

class Proxy < Rack::Proxy
  attr_accessor :upstream_url

  def initialize(app, upstream_url)
    @upstream_url = URI(upstream_url)
    super(app, backend: upstream_url, streaming: false)
  end

  def call(env)
    path = env['PATH_INFO']

    if proxy?(path)
      process_token_or_authenticate!(env)
      debug_logging(env, "Proxing request: #{path}")
      super
    else
      debug_logging(env, "Request not being proxied: #{path}")
      @app.call(env)
    end
  end

  def proxy?(path)
    !healthcheck_path?(path) && !gds_sso_path?(path)
  end

  def rewrite_env(env)
    # Proxying hangs in the VM unless the host header is explicitly overridden here.
    env['HTTP_HOST'] = upstream_url.host
    add_authenticated_user_header(env)
    env
  end

  def rewrite_response(response)
    status, headers, body = response

    [
      status,
      # We aren't returning a chunked response so remove that from the headers.
      # Also, status doesn't belong in the headers in a rack response triplet.
      headers.reject { |key, _| %w(status transfer-encoding).include?(key) },
      body
    ]
  end

private

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end

  def process_token_or_authenticate!(env)
    request = Rack::Request.new(env)
    if token = request.params['token']
      content_id = process_token(token, env)
    end
    authenticate!(env) unless content_id
  end

  def process_token(token, env)
    payload, header = JWT.decode(token, jwt_auth_secret, true, { algorithm: 'HS256' })
    env['HTTP_GOVUK_AUTH_BYPASS_ID'] = payload['sub'] if payload.key?('sub')
  rescue JWT::DecodeError
  end

  def authenticate!(env)
    if env['warden']
      user = env['warden'].authenticate!
      debug_logging(env, "authenticated as #{user.email}")
    end
  end

  def add_authenticated_user_header(env)
    env['HTTP_X_GOVUK_AUTHENTICATED_USER'] = if env['warden'] && env['warden'].user
                                               env['warden'].user.uid.to_s
                                             else
                                               'invalid'
                                             end
  end

  def healthcheck_path?(path)
    path == '/healthcheck'
  end

  def gds_sso_path?(path)
    path.starts_with?("/auth/")
  end

  def debug_logging(env, message)
    env['action_dispatch.logger'] and env['action_dispatch.logger'].debug message
  end
end
