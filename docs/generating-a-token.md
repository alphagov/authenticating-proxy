# Generating an auth bypass token

Applications which want to generate a token valid for bypassing authentication will
need to have access to the same value for the JWT_AUTH_SECRET environment variable.
They can then use the JWT library - which will probably already be present, since it
is a dependency of gds-sso via oauth2 - to encode a token as follows:

```
JWT.encode({
  "sub" => auth_bypass_id,
  "iat" => Time.zone.now.to_i,
  "exp" => 1.month.from_now.to_i,
  "content_id" => content_id,
}, ENV['JWT_AUTH_SECRET'], 'HS256')
```

Where:

- `sub` value of `auth_bypass_id` is a unique value determined by the publishing
  application for a particular draft piece of content
- `iat` ("issued at") is the time at which the token was created
- `exp` ("expiration time") is when the token should expire and no longer be
   valid
- `content_id` is the GOV.UK content id for the piece of content that is being
  shared

`sub`, `iat` and `exp` [registered claims][] as part of the JWT specification.
Applications are advised to use an expiry on tokens to limit their lifespan
and set an auth_bypass_id that is relatively simple to rotate were a token
to be accidentally made public. The `iat` and `content_id` values allow tracing
the source of a token.

[registered claim]: https://tools.ietf.org/html/rfc7519#section-4.1

## Optional special fields

In addition to the JWT standard fields, you can encode arbitrary fields which might
only have meaning for your application. For example, it is recommended that you store
some information that describes the piece of content associated with the JWT token (such
as a content ID). Do bear in mind that the data inside a JWT token is not encrypted
and **must** not include sensitive or personally identifiable data.

```
  "content_id" => step_by_step.content_id
```
