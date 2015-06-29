# authenticating-proxy

An authenticating proxy application that proxies requests to an upstream service.

## Live examples

[https://www-origin.draft.preview.publishing.service.gov.uk/](https://www-origin.draft.preview.publishing.service.gov.uk/)

## Nomenclature

- **`X-GOVUK-AUTHENTICATED-USER`**: The HTTP header which contains the UID of
  the authenticated user (as reported by signonotron).
- **upstream service**: The destination service that the app is proxying to.
- **signonotron**: Single signon service for GOV.UK authentication.
- **`GOVUK_UPSTREAM_URI`**: environment variable used to specify the upstream
  site.

## Technical documentation

This is a Rails application that proxies requests to an upstream service, first
performing authentication using `gds-sso` to ensure that only authenticated
users are able to view the site. It sets an `X-GOVUK-AUTHENTICATED-USER` header
so that the upstream service can identify the user.

### Dependencies

- [alphagov/gds-sso](http://github.com/alphagov/gds-sso) - provides
  authentication against the GOV.UK single-signon application,
  [signonotron](https://github.com/alphagov/signonotron2)
- [rack-proxy](https://github.com/ncr/rack-proxy) - rack middleware used to
  proxy requests through to the upstream service.

### Running the application

The application relies on the `GOVUK_UPSTREAM_URI` being set to run:

```
$ GOVUK_UPSTREAM_URI=https://www.dev.gov.uk ./startup.sh
```

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

```
$ bundle exec rspec
```

## Licence

[MIT License](LICENCE)
