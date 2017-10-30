require 'rails_helper'

RSpec.describe "Proxying requests", type: :request do
  let(:body) { "body" }
  let(:upstream_path) { "/foo" }
  let(:upstream_uri) { ENV['GOVUK_UPSTREAM_URI'] }

  context "unauthenticated user" do
    around do |example|
      ENV['GDS_SSO_MOCK_INVALID'] = '§1'
      example.run
      ENV.delete('GDS_SSO_MOCK_INVALID')
    end

    it "redirects the user for authentication" do
      get upstream_path

      expect(response.status).to eq(302)
      expect(response["Location"]).to eq("http://www.example.com/auth/gds")
    end

    context "with a JWT token" do
      let(:jwt_auth_secret) { 'my$ecretK3y' }
      let(:auth_bypass_id) { SecureRandom.uuid }
      let(:token) { JWT.encode({ 'sub' => auth_bypass_id }, jwt_auth_secret, 'HS256') }
      let(:inner_app) { lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['Rails app']] } }
      let(:proxy_app) { Proxy.new(inner_app, upstream_uri + upstream_path + "?token=#{token}") }
      let(:request_env) { Rack::MockRequest.env_for(upstream_uri + upstream_path + "?token=#{token}") }
      before do
        allow_any_instance_of(Proxy)
          .to receive(:jwt_auth_secret)
          .and_return(jwt_auth_secret)
      end

      it "includes the decoded auth_bypass_id in the upstream request headers" do
        expect(proxy_app)
          .to receive(:perform_request)
          .and_return([200, {"Header" => "content"}, ["body"]])
        expect(proxy_app)
          .to receive(:rewrite_env)
          .with(hash_including("HTTP_GOVUK_AUTH_BYPASS_ID" => auth_bypass_id))

        status, headers, body = proxy_app.call(request_env)
      end

      it "does not redirect the user for authentication" do
        expect(proxy_app)
          .to receive(:perform_request)
          .and_return([200, {"Header" => "content"}, ["body"]])
        status, headers, body = proxy_app.call(request_env)

        expect(status).to eq(200)
      end

      it "marks the user id as invalid in the upstream request headers" do
        expect(proxy_app.rewrite_env(request_env)).to include("HTTP_X_GOVUK_AUTHENTICATED_USER" => "invalid")
      end

      context "with an invalid token" do
        let(:token) { JWT.encode({ 'sub' => auth_bypass_id }, 'invalid', 'HS256') }
        it "redirects the user for authentication" do
          get upstream_path

          expect(response.status).to eq(302)
          expect(response["Location"]).to eq("http://www.example.com/auth/gds")
        end
      end

      context "with a token that is valid but doesn't contain the right key" do
        let(:token) { JWT.encode({ 'foo' => 'bar' }, 'invalid', 'HS256') }
        it "redirects the user for authentication" do
          get upstream_path

          expect(response.status).to eq(302)
          expect(response["Location"]).to eq("http://www.example.com/auth/gds")
        end
      end
    end
  end

  context "authenticated user" do
    let(:authenticated_user_uid) { User.first.uid }
    let(:inner_app) { lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['Rails app']] } }
    let(:proxy_app) { Proxy.new(inner_app, upstream_uri + upstream_path) }
    let(:request_env) { Rack::MockRequest.env_for(upstream_uri + upstream_path) }
    before do
      allow_any_instance_of(Proxy)
        .to receive(:perform_request)
        .and_return([200, {"Header" => "content"}, ["body"]])
    end

    it "proxies the request to the upstream server" do
      get upstream_path

      expect(response.body).to eq(body)
    end

    it "includes the user's UID in the upstream request headers" do
      expect_any_instance_of(Proxy)
        .to receive(:perform_request)
        .with(hash_including("HTTP_X_GOVUK_AUTHENTICATED_USER" => authenticated_user_uid))

      get upstream_path
    end
  end
end
