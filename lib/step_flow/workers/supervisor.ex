defmodule StepFlow.Workers.Supervisor do
  require Logger
  use Supervisor

  @moduledoc false

  @doc false
  def start_link do
    Logger.warn("#{__MODULE__} start_link")
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    Logger.warn("#{__MODULE__} init")

    children = [
      worker(StepFlow.Workers.WorkerStatusWatcher, [])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
