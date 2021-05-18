import Config

config :ex_tda,
  client_id: System.get_env("TDA_CLIENT_ID"),
  access_code: System.get_env("ACCESS_CODE")

# import_config "#{config_env()}.exs"
