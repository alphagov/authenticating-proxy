RSpec.feature "Widget management" do

  # Given I don’t have a signon account
  # When I visit a page with a valid token
  # Then I should see the page
  # When I click on a link
  # Then I should be asked to Signon
  # When I click back
  # Then I should see the original page loaded

  let(:token) { JWT.encode({ "foo" => "bar" }, jwt_auth_secret, "HS256") }

  before do
    content_item = GovukSchemas::Example.find("step_by_step_nav", example_name: "learn_to_drive_a_car")
    stub_content_store_has_item(content_item["base_path"], content_item)

    stub_request(:get, "http://upstream-host.com/api/content/examples/step_by_step_nav/learn_to_drive_a_car").
      with(
        headers: {
          'Cookie'=>'',
          'X-Forwarded-For'=>'127.0.0.1',
          'X-Govuk-Authenticated-User'=>'',
          'X-Govuk-Authenticated-User-Organisation'=>''
        }).
      to_return(status: 200, body: "", headers: {})

    visit "https://govuk-content-store-examples.herokuapp.com/api/content/examples/step_by_step_nav/learn_to_drive_a_car"
  end

  it "is a features test" do
    pp page.body
    expect(page).not_to be_nil
  end
end