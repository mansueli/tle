## Postgres TLE (Trusted Language Extensions)

This is a monorepo to keep TLE extensions to be used in your database. You'll need to have [pg_tle](https://github.com/aws/pg_tle) installed in your database.

Extensions available on [Database.dev](https://database.dev/mansueli) registry:

- [pgWebhook](https://github.com/mansueli/tle/tree/master/pgwebhook)
- [Function Version Control](https://github.com/mansueli/tle/tree/master/function_vc)
- [RLS Helpers](https://github.com/mansueli/tle/tree/master/rls_helpers)
- [Supa_queue](https://github.com/mansueli/supa_queue)
- [BrainFuck](https://github.com/mansueli/tle/tree/master/brainfuck)
- [Hello World Example](https://github.com/mansueli/tle/tree/master/hello_world)

## Automated publishing

The `update-disposable-domains` workflow automatically refreshes the `email_guard` blocklist every Monday and publishes a new version to [database.dev](https://database.dev) when changes are detected.

### Required repository secret

| Secret | Description |
|---|---|
| `DBDEV_TOKEN` | Personal access token from [database.dev](https://database.dev). Obtain it from your account settings on database.dev. |

To add the secret, go to **Settings → Secrets and variables → Actions → New repository secret** and create `DBDEV_TOKEN` with your token value.

To rotate the token, generate a new token on database.dev and update the repository secret with the new value.
