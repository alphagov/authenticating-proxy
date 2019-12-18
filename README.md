# GOV.UK Authenticating Proxy

App to add authentication to the draft version of GOV.UK, so that only users with
a [signon][] account - or a valid JSON web token ([JWT]) - can access it.

Some of the thinking behind this is [documented in RFC 13][rfc].

[JWT]: https://jwt.io/
[rfc]: https://github.com/alphagov/govuk-rfcs/blob/master/rfc-013-thoughts-on-access-limiting-in-draft.md

## Live examples

[https://www-origin.draft.preview.publishing.service.gov.uk/](https://www-origin.draft.preview.publishing.service.gov.uk/)

## Nomenclature

- **`X-GOVUK-AUTHENTICATED-USER`**: The HTTP header which contains the UID of
  the authenticated user (as reported by Signon).
- **upstream service**: The destination service that the app is proxying to.
- **Signon**: Single signon service for GOV.UK authentication.
- **`GOVUK_UPSTREAM_URI`**: environment variable used to specify the upstream
  site.
- **`GOVUK_AUTH_BYPASS_ID`**: The HTTP header which contains the UUID of a auth
  bypass, extracted from a token.

## Technical documentation

This is a Rails application that proxies requests to an upstream service, first
performing authentication using `gds-sso` to ensure that only authenticated
users are able to view the site. It sets an `X-GOVUK-AUTHENTICATED-USER` header
so that the upstream service can identify the user.

The application also supports bypassing authentication via a valid JWT token.
If the URL being requested includes a `token` querystring containing a valid
token encoded with the value in the `JWT_AUTH_SECRET` environment variable, and
that token contains a `sub` key, the value of that key is passed upstream in
the `GOVUK_AUTH_BYPASS_ID` header. NB, the `sub` (or "subject") key is one of the
[reserved claims of a JWT][].

If a user is authenticated using `gds-sso` and a JWT token is also provided, both
sets of information are passed upstream. It is up to the upstream application how
to handle these cases.

Authenticating-proxy does not itself check that the auth_bypass_id is actually
valid; this will be done by content-store.

[reserved claims of a JWT]: https://auth0.com/docs/tokens/jwt-claims#reserved-claims

### Dependencies

- [alphagov/gds-sso](http://github.com/alphagov/gds-sso) - provides
  authentication against the GOV.UK single-signon application,
  [signon][]
- [rack-proxy](https://github.com/ncr/rack-proxy) - rack middleware used to
  proxy requests through to the upstream service.
- [MongoDB](https://www.mongodb.com/)

### Setup

authenticating-proxy is not supported in [govuk-docker][] yet. In the meantime,
[use the development VM](#running-the-application-in-the-dev-vm) or set things
up manually:

```sh
bundle install
GOVUK_UPSTREAM_URI=http://www.dev.gov.uk bundle exec rails server
```

[govuk-docker]: https://github.com/alphagov/govuk-docker/

### Running the application in the dev VM

On the development VM, `GOVUK_UPSTREAM_URI` defaults to government-frontend. If
you want to run authenticating-proxy against a real running instance of signon
(instead of the usual mock-mode), then use the following `bowl` command:

```
$ GDS_SSO_STRATEGY=real bowl authenticating-proxy signon
```

Note that `GDS_SSO_STRATEGY` is set to true to stop gds-sso from using mock mode
and instead authenticate via a running local version of signon. If you are going
to run against real signon, then you will need to add authenticating-proxy as an
application in signon and also create a user with permission to access it:

```
# From the signon directory:
$ bundle exec rake applications:create name=authenticating-proxy description="authenticating proxy" home_uri="http://authenticating-proxy.dev.gov.uk" redirect_uri="http://authenticating-proxy.dev.gov.uk/auth/gds/callback"
$ bundle exec rake users:create name='User Name' email=user@email.com applications=authenticating-proxy
```

### Running the test suite

You will need to follow the [setup instructions](#setup), then:

```
$ bundle exec rspec
```

### Generating a auth bypass token

Applications which want to generate a token valid for bypassing authentication will
need to have access to the same value for the JWT_AUTH_SECRET environment variable.
They can then use the JWT library - which will probably already be present, since it
is a dependency of gds-sso via oauth2 - to encode a token as follows:

```
JWT.encode({
  "sub" => auth_bypass_id,
  "iss" => current_user.uid,
  "iat" => Time.zone.now.to_i,
  "exp" => 1.month.from_now.to_i,
}, ENV['JWT_AUTH_SECRET'], 'HS256')
```

Where:

- `sub` value of `auth_bypass_id` is the UUID for the auth bypass of the content item
- `iss` ("issuer") is the unique ID of the user who created the token
- `iat` ("issued at") is the time at which the token was created
- `exp` ("expiration time") is when the token should expire and no longer be valid

These fields are [registered claim names][] in the JWT specification. Providing
them is recommended as they help to audit when and how the token was created and when
it should expire.

[registered claim names]: https://tools.ietf.org/html/rfc7519#section-4.1

#### Optional special fields

In addition to the JWT standard fields, you can encode arbitrary fields which might
only have meaning for your application. For example, it is recommended that you store
some information that describes the piece of content associated with the JWT token (such
as a content ID). Do bear in mind that the data inside a JWT token is not encrypted
and **must** not include sensitive or personally identifiable data.

```
  "content_id" => step_by_step.content_id
```

## Licence

[MIT License](LICENCE)

[signon]: https://github.com/alphagov/signon
