defmodule StepFlow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias StepFlow.Metrics
  alias StepFlow.Migration
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    options = %{
      keepalive: 10_000,
      name: :step_flow_slack_bot,
      scope: "identify,incoming-webhook"
    }

    children = [
      supervisor(StepFlow.Repo, []),
      supervisor(StepFlow.Amqp.Supervisor, []),
      worker(StepFlow.Workflows.StepManager, [])
    ]

    children =
      case Application.get_env(:step_flow, StepFlow.Endpoint) do
        nil ->
          children

        _ ->
          children ++
            [
              {Phoenix.PubSub, [name: StepFlow.PubSub, adapter: Phoenix.PubSub.PG2]},
              supervisor(StepFlow.Endpoint, [])
            ]
      end

    children =
      StepFlow.Configuration.get_slack_token()
      |> case do
        nil ->
          children

        slack_token ->
          Logger.info("Starting Slack Bot")

          List.insert_at(
            children,
            -1,
            worker(Slack.Bot, [StepFlow.SlackBot, [], slack_token, options], restart: :transient)
          )
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StepFlow.Supervisor]
    supervisor = Supervisor.start_link(children, opts)
    Migration.All.apply_migrations()

    WorkflowDefinition.load_workflows_in_database()

    # Start prometheus exporter and instrumenters
    if StepFlow.Configuration.metrics_enabled?() do
      Metrics.WorkflowInstrumenter.setup()
      Metrics.JobInstrumenter.setup()
      StepFlow.MetricController.setup()
    end

    supervisor
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    StepFlow.Endpoint.config_change(changed, removed)
    :ok
  end
end
