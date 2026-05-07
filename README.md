# Geolocations API

A Rails JSON API for storing and retrieving geolocation data for IP addresses and URLs/hostnames using `ipstack`.

- Auth: JWT via `devise-jwt`
- Serialization: JSON:API-style payloads via `jsonapi-serializer`
- Pagination: `kaminari`
- Rate limiting: `rack-attack`
- API docs: Swagger UI via `rswag`

## Quick start

1. Install dependencies:

```bash
bundle install
```

2. Create environment files:

```bash
cp .env.example .env.development
cp .env.example .env.test
```

3. Update database names as needed:

- `.env.development`: keep `POSTGRES_DB=geolocations_api_development`
- `.env.test`: change `POSTGRES_DB=geolocations_api_test`

4. Create and migrate the databases:

```bash
rails db:create db:migrate
```

5. Start the server:

```bash
bin/rails server
```

The API is available at `http://localhost:3000`.

## API docs

Swagger UI is available at:

- `http://localhost:3000/api-docs`

Raw OpenAPI JSON is available at:

- `http://localhost:3000/api-docs/v1/openapi.json`

Regenerate the OpenAPI file after changing endpoints or response shapes:

```bash
bundle exec rspec spec/requests/api_docs_spec.rb --format Rswag::Specs::SwaggerFormatter --order defined
```

This writes the current API contract to `openapi/v1/openapi.json`.

## Environment variables

This project uses `dotenv-rails` with environment-specific files:

- `.env.development`
- `.env.test`

Tracked template:

- `.env.example`

| Variable | Description |
|---|---|
| `IPSTACK_ACCESS_KEY` | ipstack API key |
| `DEVISE_JWT_SECRET_KEY` | JWT signing secret |
| `RAILS_MAX_THREADS` | Puma / Active Record thread pool |
| `POSTGRES_HOST` | PostgreSQL host |
| `POSTGRES_USER` | PostgreSQL username |
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `POSTGRES_DB` | Database name for the current environment file |
| `DATABASE_URL` | Production connection string |

## Authentication

All `/api/v1/geolocations` endpoints require a bearer token:

```text
Authorization: Bearer <JWT>
```

JWTs are returned in the `Authorization` response header from:

- `POST /api/v1/users/sign_up`
- `POST /api/v1/users/sign_in`

`POST /api/v1/users/sign_in` also returns the JWT in `data.attributes.token` for easier frontend consumption.

The JWT payload expires after 24 hours.

## Geolocation fields

Every geolocation response includes these `data.attributes` fields:

| Field | Type | Notes |
|---|---|---|
| `ip` | string or null | Resolved IP address |
| `url` | string or null | Normalized URL such as `https://google.com` |
| `lookup_key` | string | Unique lookup identifier used for fetch/delete |
| `country_name` | string or null | Country name from provider |
| `country_code` | string or null | ISO-style country code |
| `region_name` | string or null | Region/state name |
| `region_code` | string or null | Region/state code |
| `city` | string or null | City name |
| `zip` | string or null | Postal code |
| `latitude` | string or null | Decimal value serialized as a string |
| `longitude` | string or null | Decimal value serialized as a string |
| `provider` | string | `ipstack` or `null` in tests |
| `created_at` | ISO 8601 string | Record creation timestamp |
| `updated_at` | ISO 8601 string | Record update timestamp |

## Endpoint summary

### `POST /api/v1/users/sign_up`

Creates a user.

Request body:

```json
{
  "user": {
    "email": "new@example.com",
    "password": "Password1!",
    "password_confirmation": "Password1!"
  }
}
```

Success:

- `201 Created`
- Response body contains the user resource
- `Authorization` response header contains the bearer token

Validation errors:

- `422 Unprocessable Content`

### `POST /api/v1/users/sign_in`

Authenticates an existing user.

Request body:

```json
{
  "user": {
    "email": "login@example.com",
    "password": "Password1!"
  }
}
```

Success:

- `200 OK`
- Response body contains the user resource and `data.attributes.token`
- `Authorization` response header contains the bearer token

Errors:

- `401 Unauthorized` for invalid credentials

### `DELETE /api/v1/users/sign_out`

Revokes the current JWT.

Success:

- `204 No Content`

Current behavior:

- returns `204` even if the `Authorization` header is missing

### `GET /api/v1/geolocations`

Returns stored geolocations ordered by newest first.

Query params:

- `page[number]`
- `page[size]`

Success:

- `200 OK`
- Response contains `data` and pagination `meta`

Errors:

- `401 Unauthorized`

### `POST /api/v1/geolocations`

Creates or refreshes a geolocation from exactly one input:

- `ip`
- `url`

Request body:

```json
{
  "data": {
    "type": "geolocations",
    "attributes": {
      "ip": "1.2.3.4"
    }
  }
}
```

URL behavior:

- accepts full URLs like `https://example.com`
- accepts bare hostnames like `google.com`
- normalizes hostnames to `https://<host>`
- resolves the hostname to an IP before provider lookup

Upsert behavior:

- returns `201 Created` for a new record
- returns `200 OK` when the same `lookup_key` already exists and is updated

Errors:

- `400 Bad Request`
- `401 Unauthorized`
- `422 Unprocessable Content`
- `429 Too Many Requests`
- `502 Bad Gateway`
- `504 Gateway Timeout`
- `500 Internal Server Error`

### `GET /api/v1/geolocations/:lookup_key`

Fetches a stored geolocation by `lookup_key`.

Notes:

- URL-style lookup keys must be URL-encoded
- example: `/api/v1/geolocations/https%3A%2F%2Fgoogle.com`

Success:

- `200 OK`

Errors:

- `401 Unauthorized`
- `404 Not Found`

### `DELETE /api/v1/geolocations/:lookup_key`

Deletes a stored geolocation by `lookup_key`.

Success:

- `204 No Content`

Errors:

- `401 Unauthorized`
- `404 Not Found`

### `GET /up`

Rails health check endpoint.

## Error format

Errors use a JSON:API-style `errors` array:

```json
{
  "errors": [
    {
      "status": "422",
      "code": "invalid_url",
      "title": "Invalid URL",
      "detail": "URL is invalid"
    }
  ]
}
```

### Common error codes

| Status | Code | Meaning |
|---|---|---|
| `400` | `missing_parameter` | Required wrapper or attribute is missing |
| `400` | `ambiguous_parameter` | Both `ip` and `url` were provided |
| `401` | `unauthorized` | Missing or invalid authentication |
| `404` | `not_found` | Resource was not found |
| `422` | `invalid_ip` | Invalid IP format |
| `422` | `invalid_url` | Invalid URL format |
| `422` | `dns_resolution_failed` | Hostname could not be resolved |
| `422` | `validation_error` | Active Record or signup validation failed |
| `429` | `quota_exceeded` | Provider quota exceeded |
| `502` | `provider_error` | Provider returned an unexpected error |
| `504` | `provider_timeout` | Provider request timed out |
| `500` | `internal_error` | Unexpected server-side failure |

## Testing

Run the full suite:

```bash
bundle exec rspec
```

Useful commands:

```bash
bundle exec rspec spec/requests/
bundle exec rspec spec/lib/geolocation/ipstack_provider_spec.rb
bundle exec rspec spec/requests/api_docs_spec.rb
```

Notes:

- SimpleCov writes coverage output to `coverage/index.html`
- VCR cassettes are stored in `spec/vcr_cassettes`
- successful ipstack flows use VCR
- provider error branches use WebMock stubs
- test uses `NullProvider` by default unless a spec explicitly instantiates `IpstackProvider`

## Architecture notes

| Concern | Implementation |
|---|---|
| Auth | `devise` + `devise-jwt` |
| Serialization | `jsonapi-serializer` |
| Geolocation lookup | `GeolocationLookupResolver` + `GeolocationLookupService` |
| Provider adapter | `GeolocationProviders::IpstackProvider` |
| Test provider | `GeolocationProviders::NullProvider` |
| HTTP client | `faraday` + `faraday-retry` |
| Pagination | `kaminari` |
| Rate limiting | `rack-attack` |
