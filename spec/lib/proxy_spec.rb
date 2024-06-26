RSpec.describe Proxy do
  let(:upstream_body) { "hello" }
  let(:upstream_headers) do
    {
      "Content-Type" => "text/plain",
      "Transfer-Encoding" => "chunked",
      "Status" => "200 OK",
    }
  end
  let(:upstream_path) { "/foo" }
  let(:upstream_uri) { ENV["GOVUK_UPSTREAM_URI"] }
  let(:inner_app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["Rails App"]] } }
  let(:request_env) { Rack::MockRequest.env_for(upstream_path) }
  let(:proxy_app) { described_class.new(inner_app, upstream_uri) }

  before do
    stub_warden_authentication
    stub_request(:get, upstream_uri + upstream_path)
      .to_return(body: upstream_body, status: 200, headers: upstream_headers)
  end

  it "returns the response from the upstream URI" do
    _status, _headers, body = proxy_app.call(request_env)

    expect(body).to eq([upstream_body])
  end

  it "does not proxy /healthcheck/live requests" do
    _status, _headers, body = proxy_app.call(request_env.merge({ "PATH_INFO" => "/healthcheck/live" }))

    expect(body).to eq(["Rails App"])
  end

  it "does not proxy /healthcheck/ready requests" do
    _status, _headers, body = proxy_app.call(request_env.merge({ "PATH_INFO" => "/healthcheck/ready" }))

    expect(body).to eq(["Rails App"])
  end

  describe "#rewrite_response" do
    let(:status) { 200 }
    let(:body) { ["1234 1234 1234 1234"] }
    let(:response) { [status, { "Content-Length" => "5" }, body] }

    it "corrects an incorrect content-length header" do
      rewrote = proxy_app.rewrite_response(response)
      expect(rewrote).to match([status, { "Content-Length" => "19" }, body])
    end
  end

  def stub_warden_authentication
    request_env["warden"] = instance_double(
      Warden::Proxy,
      authenticate: stub_user,
      authenticate!: stub_user,
      user: stub_user,
    )
  end

  def stub_user
    @stub_user ||= instance_double(
      User,
      uid: User.first.uid,
      organisation_content_id: User.first.organisation_content_id,
      email: "example@gov.uk",
    )
  end
end
