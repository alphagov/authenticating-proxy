# GOV.UK Authenticating Proxy

App to add authentication to the draft version of GOV.UK, so that only users with
a [signon][] account - or a valid JSON web token ([JWT]) - can access it.

This is a Rails application that [proxies][] requests to an upstream service, first
performing authentication using [gds-sso][] to ensure that only authenticated
users are able to view the site. It sets an `X-GOVUK-AUTHENTICATED-USER` header
so that the upstream service can identify the user.

The application also supports bypassing authentication via a valid JWT token.
If the URL being requested includes a `token` querystring containing a valid
token encoded with the value in the `JWT_AUTH_SECRET` environment variable, and
that token contains a `sub` key, the value of that key is passed upstream in
the `GOVUK_AUTH_BYPASS_ID` header. NB, the `sub` (or "subject") key is one of the
[reserved claims of a JWT][].

If a user is authenticated using [gds-sso][] and a JWT token is also provided, both
sets of information are passed upstream. It is up to the upstream application how
to handle these cases.

Some of the thinking behind this is [documented in RFC 13][rfc].

[rfc]: https://github.com/alphagov/govuk-rfcs/blob/master/rfc-013-thoughts-on-access-limiting-in-draft.md
[JWT]: https://jwt.io/
[reserved claims of a JWT]: https://auth0.com/docs/tokens/jwt-claims#reserved-claims
[gds-sso]: http://github.com/alphagov/gds-sso
[proxies]: https://github.com/ncr/rack-proxy

## Technical documentation

### Running the app ([mock mode](https://github.com/alphagov/gds-sso#use-in-development-mode))

In GOV.UK Docker, `GOVUK_UPSTREAM_URI` defaults to government-frontend. This
means that, when you request `authenticating-proxy.dev.gov.uk`, it should behave
the same as requesting `government-frontend.dev.gov.uk`.

### Running the app (real mode)

If you want to run authenticating-proxy against a real running instance of signon
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

### Further documentation

Check the [`docs/`](docs/) directory.

## Licence

[MIT License](LICENCE)

[signon]: https://github.com/alphagov/signon
