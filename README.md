# GOV.UK Authenticating Proxy

App to add authentication to the draft version of GOV.UK, so that only users with
a [signon][] account - or a valid JSON web token ([JWT]) - can access it.

This is a Rails application that [proxies][] requests to an upstream service, first
performing authentication using [gds-sso][] to ensure that only authenticated
users are able to view the site. It sets a `X-GOVUK-AUTHENTICATED-USER` header and a 
`X_GOVUK_AUTHENTICATED_USER_ORGANISATION` header so that the upstream service can identify the user.

It also removes the `Host` header and replaces it with a `X-Forwarded-Host` header.

The application also supports bypassing authentication via a valid JWT token.
If the URL being requested includes a `token` querystring containing a valid
token encoded with the value in the `JWT_AUTH_SECRET` environment variable, and
that token contains a `sub` key, the value of that key is passed upstream in
the `GOVUK_AUTH_BYPASS_ID` header. NB, the `sub` (or "subject") key is one of the
[reserved claims of a JWT][].

If a user is authenticated using [gds-sso][] and a JWT token is also provided, both
sets of information are passed upstream. It is up to the upstream application how
to handle these cases.

See the [request flow](https://github.com/alphagov/router?tab=readme-ov-file#draft-stack) with draft router.

Some of the thinking behind this is [documented in RFC 13][rfc].

[rfc]: https://github.com/alphagov/govuk-rfcs/blob/master/rfc-013-thoughts-on-access-limiting-in-draft.md
[JWT]: https://jwt.io/
[reserved claims of a JWT]: https://auth0.com/docs/tokens/jwt-claims#reserved-claims
[gds-sso]: http://github.com/alphagov/gds-sso
[proxies]: https://github.com/ncr/rack-proxy

## Technical documentation

The proxy works by subclassing [rack-proxy](https://github.com/ncr/rack-proxy/blob/57973871f4f8fa1cf6cd7bc73d7c042201ec20b4/lib/rack/proxy.rb) methods (e.g. `call` to perform the request)

### Running the app

In GOV.UK Docker, `GOVUK_UPSTREAM_URI` defaults to `frontend`. This
means that, when you request `authenticating-proxy.dev.gov.uk`, it should behave
the same as requesting `frontend.dev.gov.uk`.

### Running the test suite

```
bundle exec rake
```

### Further documentation

Check the [`docs/`](docs/) directory.

## Licence

[MIT License](LICENCE)

[signon]: https://github.com/alphagov/signon
