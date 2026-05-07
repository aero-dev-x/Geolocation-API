# Geolocations API

A Rails JSON API for storing and retrieving geolocation data for IP addresses and URLs/hostnames using ipstack.

- Auth: JWT via `devise-jwt`
- Geolocation storage: upsert by `lookup_key`
- Pagination: `kaminari` with JSON:API-style `meta`
- Provider abstraction: swappable provider adapter, `IpstackProvider` in normal use and `NullProvider` in test
- Rate limiting: `rack-attack`

## Quick start

### Local setup

1. Install dependencies:

```bash
bundle install
```

2. Create env files from the template:

```bash
cp .env.example .env.development
cp .env.example .env.test
```

3. Update the database names:

- `.env.development`: keep `POSTGRES_DB=geolocations_api_development`
- `.env.test`: set `POSTGRES_DB=geolocations_api_test`

4. Create and migrate the databases:

```bash
rails db:create db:migrate
```

5. Start the server:

```bash
bin/rails server
```

The API is available at `http://localhost:3000`.

## Environment files

This project uses `dotenv-rails` with separate environment files:

- `.env.development`
- `.env.test`

Tracked templates:

- `.env.example`

Important variables:

| Variable | Used in | Description |
|---|---|---|
| `IPSTACK_ACCESS_KEY` | development, test | ipstack API key |
| `DEVISE_JWT_SECRET_KEY` | development, test, production | JWT signing secret |
| `POSTGRES_HOST` | development, test | PostgreSQL host |
| `POSTGRES_USER` | development, test | PostgreSQL user |
| `POSTGRES_PASSWORD` | development, test | PostgreSQL password |
| `POSTGRES_DB` | development | Development database name |
| `POSTGRES_DB_TEST` | test | Test database name |
| `DATABASE_URL` | production | Production connection string |

## Authentication

All `/api/v1/geolocations` endpoints require a bearer token from sign-up or sign-in.

```text
Authorization: Bearer <JWT>
```

JWTs expire after 24 hours. Signing out revokes the current token.

## Endpoints

### `POST /api/v1/users/sign_up`

Creates a user and returns a JWT in the `Authorization` response header.

### `POST /api/v1/users/sign_in`

Signs in an existing user and returns a JWT in the `Authorization` response header.

### `DELETE /api/v1/users/sign_out`

Revokes the current JWT and returns `204 No Content`.

### `GET /api/v1/geolocations`

Returns stored geolocations ordered by newest first.

Query params:

- `page[number]`
- `page[size]`

### `POST /api/v1/geolocations`

Creates or refreshes a geolocation record from exactly one of:

- `ip`
- `url`

URL behavior:

- accepts full URLs like `https://example.com`
- accepts bare hostnames like `google.com`
- normalizes hostnames to `https://<host>`
- resolves the host to an IP before provider lookup

Upsert behavior:

- if the same `lookup_key` already exists, the record is updated and the response is `200 OK`
- otherwise a new record is created and the response is `201 Created`

### `GET /api/v1/geolocations/:lookup_key`

Fetches a stored geolocation by lookup key. URL-style lookup keys must be URL-encoded.

Example:

```text
/api/v1/geolocations/https%3A%2F%2Fgoogle.com
```

### `DELETE /api/v1/geolocations/:lookup_key`

Deletes a stored geolocation by lookup key.

### `GET /up`

Rails health check endpoint.

## Error responses

Errors are returned in a JSON:API-style `errors` array.

Common geolocation error codes:

| Status | Code | Meaning |
|---|---|---|
| `400` | `missing_parameter` | Neither `ip` nor `url` was provided |
| `400` | `ambiguous_parameter` | Both `ip` and `url` were provided |
| `422` | `invalid_ip` | Invalid IP format |
| `422` | `invalid_url` | Invalid URL format |
| `422` | `dns_resolution_failed` | Hostname could not be resolved |
| `422` | `validation_error` | Model validation failed |
| `429` | `quota_exceeded` | Provider quota exceeded |
| `502` | `provider_error` | Provider returned an unexpected error |
| `504` | `provider_timeout` | Provider timed out |

## Testing

Run the full suite:

```bash
bundle exec rspec
```

Useful commands:

```bash
bundle exec rspec spec/requests/
bundle exec rspec spec/lib/geolocation/ipstack_provider_spec.rb
```

Notes:

- SimpleCov writes coverage output to `coverage/index.html`
- VCR cassettes are stored in `spec/vcr_cassettes`
- the successful ipstack flows use VCR; provider error branches use WebMock stubs
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
