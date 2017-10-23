require 'rails_helper'
require 'rack'

RSpec.describe Proxy do
  let(:upstream_body) { 'hello' }
  let(:upstream_headers) do
    {
      'Content-Type' => 'text/plain',
      'Transfer-Encoding' => 'chunked',
      'Status' => '200 OK',
    }
  end
  let(:upstream_path) { "/foo" }
  let(:upstream_uri) { ENV['GOVUK_UPSTREAM_URI'] }
  let(:inner_app) { lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['Rails App']] } }
  let(:request_env) { Rack::MockRequest.env_for(upstream_path) }
  let(:proxy_app) { Proxy.new(inner_app, upstream_uri) }

  it 'passes Rack::Lint checks' do
    allow(proxy_app).to receive(:perform_request)
      .and_return([200, {"Content-Type" => "text/html; charset=UTF-8"}, ["hello"]])

    lint_app = Rack::Lint.new(proxy_app)

    lint_app.call(request_env)
  end

  it 'returns the response from the upstream URI' do
    allow(proxy_app).to receive(:perform_request)
      .and_return([200, {"Content-Type" => "text/html; charset=UTF-8"}, ["hello"]])

    status, headers, body = proxy_app.call(request_env)

    expect(body).to eq([upstream_body])
  end

  it 'does not proxy /healthcheck requests' do
    status, headers, body = proxy_app.call(request_env.merge({ "PATH_INFO" => "/healthcheck"}))

    expect(body).to eq(['Rails App'])
  end
end
