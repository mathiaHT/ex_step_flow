use Mix.Config

config :step_flow, StepFlow.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  pubsub_server: StepFlow.PubSub

config :step_flow, StepFlow.Endpoint,
  live_reload: [
    patterns: [
      ~r{lib/step_flow/.*(ex)$},
      ~r{lib/step_flow/*/.*(ex)$}
    ]
  ],
  reloadable_compilers: [:gettext, :phoenix, :elixir, :phoenix_swagger]

# config :step_flow, StepFlow.Repo,
#   migration_source: "some_other_table_for_schema_migrations",
#   migration_repo: AnotherRepoForSchemaMigrations

config :step_flow, StepFlow.Repo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "step_flow_dev",
  runtime_poll_size: 10

config :step_flow, StepFlow.Amqp,
  hostname: "localhost",
  port: 5672,
  username: "guest",
  password: "guest",
  virtual_host: ""

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :debug

config :step_flow, StepFlow.WorkflowDefinitions.ExternalLoader,
  specification_folder: "/Users/marco/dev/mcai/media-cloud-ai.github.com"

if File.exists?("config/dev.secret.exs") do
  import_config "dev.secret.exs"
end
