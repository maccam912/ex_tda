# ExTda

ExTda helps Elixir users use the TDAmeritrade API.

To use this, set the `TDA_CLIENT_ID` environment variable to your developer Client ID. `.envrc.example` is an example file that, once renamed to just `.envrc`, can be used with direnv.

To get your developer Client ID sign in at https://developer.tdameritrade.com with your TDAmeritrade brokerage account and go to the `My Apps` tab. Create an app with the callback url of `https://127.0.0.1:4000`. The Client ID here is what you need.

To use ExTda, make sure `.envrc` is updated with your Client ID, and generate self-signed certificates for a local https server in the root directory:

```
openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out localhost.crt -keyout localhost.key
```

Finally, use `iex -S mix` to start up an elixir repl, which also starts a local https server on port 4000. Visit `https://12.0.0.1:4000` and TDAmeritrade should ask you to log in. Log in with your brokerage account, allow the permissions warning, and you will be redirected back to `https://12.0.0.1:4000?code=...` which should do the rest for you. At this point the rest of the functions in module `ExTda.Client` should work. You can run `ExTda.Client.get_access_token/0` which, if you get a token, means things are working. In order to get a token from that the `refresh_token` must be valid.