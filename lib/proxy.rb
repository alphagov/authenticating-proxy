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
      super.tap do |response|
        set_auth_bypass_cookie(response, env)
        token_rejected = forbidden_response?(response) && !gds_sso_path?(path)
        env["warden"].authenticate! if token_rejected
      end
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
    add_authenticated_user_organisation_header(env)
    env
  end

  def rewrite_response(response)
    status, headers, body = response

    allow_iframing(headers)
    fix_content_length(headers, body)

    [
      status,
      # Status doesn't belong in the headers in a rack response triplet.
      headers.reject { |key, _| %w(status).include?(key) },
      body
    ]
  end

private

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end

  def process_token_or_authenticate!(env)
    request = Rack::Request.new(env)
    if token = request.params.fetch("token", get_auth_bypass_cookie(env))
      auth_bypass_id = process_token(token, env)
    end
    user = auth_bypass_id ? env['warden'].authenticate : env['warden'].authenticate!
    debug_logging(env, "authenticated as #{user.email}") if user
  end

  def get_auth_bypass_cookie(env)
    cookie = Rack::Utils.parse_cookies(env)
    cookie["auth_bypass_token"] if cookie
  end

  def set_auth_bypass_cookie(response, env)
    request = Rack::Request.new(env)
    return response unless request.params['token']

    # Override any existing token, we don't really care at this point if the
    # token is valid that's up to the consuming app to validate
    Rack::Utils.set_cookie_header!(
      response[1],
      'auth_bypass_token',
      {
        value: request.params['token'],
        path: '/',
        domain: '.' + Plek.new.external_domain,
      }
    )

    response
  end

  def forbidden_response?(response)
    response[0] == "403"
  end

  def process_token(token, env)
    payload, header = JWT.decode(token, jwt_auth_secret, true, { algorithm: 'HS256' })
    env['HTTP_GOVUK_AUTH_BYPASS_ID'] = payload['sub'] if payload.key?('sub')
  rescue JWT::DecodeError
  end

  def add_authenticated_user_header(env)
    env['HTTP_X_GOVUK_AUTHENTICATED_USER'] = if env['warden'].user
                                               env['warden'].user.uid.to_s
                                             else
                                               'invalid'
                                             end
  end

  def add_authenticated_user_organisation_header(env)
    env['HTTP_X_GOVUK_AUTHENTICATED_USER_ORGANISATION'] = if env['warden'].user
                                                            env['warden'].user.organisation_content_id.to_s
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

  # Content-Length header can end up with an incorrect value as Net::HTTP will
  # decompress a body of a gzipped request but pass throguh the Content-Length
  # header of the compressed content.
  def fix_content_length(headers, body)
    content_length_header = headers.keys.find { |k| k.downcase == "content-length" }
    return unless content_length_header

    if body.all? { |b| b.respond_to?(:bytesize) }
      bytesize = body.map(&:bytesize).sum
      headers[content_length_header] = bytesize.to_s
    else
      headers.delete(content_length_header)
    end
    bytesize = body.map(&:bytesize)
  end

  def allow_iframing(headers)
    headers.delete('X-Frame-Options')
  end
end
