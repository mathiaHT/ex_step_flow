use Mix.Config

config :phoenix, :json_library, Jason

config :step_flow, ecto_repos: [StepFlow.Repo]

config :step_flow, StepFlow,
  exposed_domain_name: {:system, "EXPOSED_DOMAIN_NAME"},
  slack_api_token: {:system, "SLACK_API_TOKEN"}

config :phoenix_swagger,
  json_library: Jason

config :step_flow, :phoenix_swagger,
  swagger_files: %{
    "priv/static/step_flow_swagger.json" => [
      router: StepFlow.Router
    ]
  }

import_config "#{Mix.env()}.exs"
