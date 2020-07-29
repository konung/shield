# Shield

*Shield* is a comprehensive security solution for [*Lucky* framework](https://luckyframework.org). It features robust authentication and authorization, including:

- User registrations
- Logins and logouts
- Login notifications (per-user setting)
- Password change notifications (per-user setting)
- Password resets

...and more

*Shield* securely hashes password reset and login tokens, before saving them to the database.

User IDs are never saved in session. Instead, each password reset or login gets a unique ID and token, which is saved in session, and checked against corresponding values in the database.

On top of these, *Shield* offers seamless integration with your application. For the most part, `include` a bunch of `module`s in the appropriate `class`es, and you are good to go!

## Documentation

Find the complete documentation of *Shield* in the `docs/` directory of this repository.

## Development

Run tests with `docker-compose -f spec/docker-compose.yml run --rm spec`. If you need to update shards before that, run `docker-compose -f spec/docker-compose.yml run --rm shards`.

If you would rather run tests on your local machine (ie, without docker), create a `.env.sh` file:

```bash
#!bin/bash

export APP_DOMAIN=http://localhost:5000
export DATABASE_URL='postgres://postgres:password@localhost:5432/shield_spec'
export SECRET_KEY_BASE='XeqAgSy5QQ+dWe8ruOBUMrz9XPbPZ7chPVtz2ecDGss='
export SERVER_HOST='0.0.0.0'
export SERVER_PORT=5000
```

Update the file with your own details. Then run tests with `source .env.sh && crystal spec`.

## Contributing

1. [Fork it](https://github.com/your-github-user/shield/fork)
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new Pull Request

## Security

Kindly report suspected security vulnerabilities in private, via contact details outlined in this repository's `.security.txt` file.
