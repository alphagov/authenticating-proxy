require 'rails_helper'

RSpec.describe "Proxying requests", type: :request do
  let(:body) { "abc" }
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

    it "allows iframing" do
      stub_request(:get, upstream_uri + upstream_path).to_return(body: body, headers: { 'X-Frame-Options' => 'DENY' })

      get upstream_path

      expect(response.headers['X-Frame-Options']).to be_nil
    end

    context "with a JWT token" do
      let(:jwt_auth_secret) { 'my$ecretK3y' }
      let(:auth_bypass_id) { SecureRandom.uuid }
      let(:token) { JWT.encode({ 'sub' => auth_bypass_id }, jwt_auth_secret, 'HS256') }
      before do
        allow_any_instance_of(Proxy).to receive(:jwt_auth_secret).and_return(jwt_auth_secret)
        stub_request(:get, upstream_uri + upstream_path + "?token=#{token}").to_return(body: body)
        get "#{upstream_path}?token=#{token}"
      end

      it "includes the decoded auth_bypass_id in the upstream request headers" do
        expect(WebMock).to have_requested(:get, upstream_uri + upstream_path + "?token=#{token}").
          with(headers: { 'Govuk-Auth-Bypass-Id' => auth_bypass_id })
      end

      it "does not redirect the user for authentication" do
        expect(response.status).to eq(200)
      end

      it "marks the user id as invalid in the upstream request headers" do
      expect(WebMock).to have_requested(:get, upstream_uri + upstream_path + "?token=#{token}").
        with(headers: { 'X-Govuk-Authenticated-User' => 'invalid' })
      end

      it "sets a cookie with the auth bypass token" do
        expect(response.cookies["auth_bypass_token"]).to eq(token)
      end

      it "sets the appropriate environment as the cookie domain" do
        ENV["GOVUK_APP_DOMAIN_EXTERNAL"] = "integration.publishing.service.gov.uk"
        get "#{upstream_path}?token=#{token}"
        expect(response.headers["Set-Cookie"]).to match("domain=.integration.publishing.service.gov.uk")
        ENV.delete("GOVUK_APP_DOMAIN_EXTERNAL")
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
    before do
      stub_request(:get, upstream_uri + upstream_path).to_return(body: body)
      get upstream_path
    end

    it "proxies the request to the upstream server" do
      expect(response.body).to eq(body)
    end

    it "includes the user's UID in the upstream request headers" do
      expect(WebMock).to have_requested(:get, upstream_uri + upstream_path).
        with(headers: { 'X-Govuk-Authenticated-User' => authenticated_user_uid })
    end
  end
end
