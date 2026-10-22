# Running

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

# Deployment
Deployment automatically happens on a Github push to https://happyfakenews.com with a Github Action.

Configure `AIRTABLE_PERSONAL_ACCESS_TOKEN` in the deployment's secret store before
deploying. Airtable reads and publishing load this value at runtime and fail before
sending a request when it is missing or empty. Never commit the token or place it
in build arguments. Previously exposed tokens must be revoked in the owning
Airtable account; removing them from current source does not revoke them.
