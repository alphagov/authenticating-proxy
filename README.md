# govuk-authenticating-proxy

An authenticating proxy application that proxies requests to an upstream site.

## Live examples

[https://www-origin.draft.preview.publishing.service.gov.uk/](https://www-origin.draft.preview.publishing.service.gov.uk/)

## Nomenclature

- **`X-GOVUK-AUTHENTICATED-USER`**: The HTTP header which contains the ID number
   of the authenticated user (as reported by signonotron).
- **upstream site**: The destination site that the app is proxying through to.
- **signonotron**: Single signon service for GOV.UK authentication.
- **`GOVUK_UPSTREAM_URI`**: environment variable used to specify the upstream
  site.

## Technical documentation

This is a Rails application that proxies requests to an upstream site, first
performing authentication using `gds-sso` to ensure that only authenticated
users are able to view the site. It sets an `X-GOVUK-AUTHENTICATED-USER` header
so that the upstream site can identify the user.

### Dependencies

- [alphagov/gds-sso](http://github.com/alphagov/gds-sso) - provides
  authentication against the GOV.UK single-signon application,
  [signonotron](https://github.com/alphagov/signonotron2)
- [rack-proxy](https://github.com/ncr/rack-proxy) - rack middleware used to
  proxy requests through to the upstream site.

### Running the application

```
$ GOVUK_UPSTREAM_URI=https://www.dev.gov.uk ./startup.sh
```

### Running the test suite

```
$ bundle exec rake
```

## Licence

[MIT License](LICENCE)
