defmodule StepFlow.Workers.WorkerStatusWatcher do
  require Logger

  @moduledoc false

  use GenServer
  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Workers.WorkerStatuses

  @default_workers_status_interval 10_000

  def start_link(workers_status \\ %{}) do
    GenServer.start_link(__MODULE__, workers_status, name: __MODULE__)
  end

  def update_worker_status(instance_id, worker_status) do
    GenServer.cast(__MODULE__, {:push, instance_id, worker_status})
  end

  def get_worker_status(instance_id) do
    GenServer.call(__MODULE__, :pop, instance_id)
  end

  @impl true
  def init(workers_status) do
    Logger.info("[#{__MODULE__}] Start checking workers status!")

    check_workers_status()

    {:ok, workers_status}
  end

  @impl true
  def handle_info(:check, workers_status) do
    Logger.debug(
      "[#{__MODULE__}] Check workers status. Current workers: #{inspect(workers_status)}"
    )

    # Schedule once more
    check_workers_status()

    {:noreply, workers_status}
  end

  @impl true
  def handle_call(:pop, instance_id, workers_status) do
    Logger.info(
      "[#{__MODULE__}] Get worker #{instance_id} status from : #{inspect(workers_status)}"
    )

    worker_status = WorkerStatuses.get_worker_status!(instance_id)
    {:reply, worker_status, workers_status}
  end

  @impl true
  def handle_cast({:push, instance_id, worker_status}, workers_status) do
    case WorkerStatuses.get_worker_status(instance_id) do
      nil ->
        Logger.info(
          "[#{__MODULE__}] Add #{instance_id} worker to workers status: #{inspect(workers_status)}"
        )

        WorkerStatuses.create_worker_status!(worker_status)

      status ->
        Logger.info(
          "[#{__MODULE__}] Update #{instance_id} worker status: #{inspect(workers_status)}"
        )

        WorkerStatuses.update_worker_status!(status, worker_status)
    end

    workers_status = WorkerStatuses.list_worker_statuses()

    Logger.info(
      "[#{__MODULE__}] Notify that workers status have been updated: #{inspect(workers_status)}"
    )

    StepFlow.Notification.send("workers_status_updated", %{
      content: StepFlow.WorkerStatusView.render("index.json", workers_status)
    })

    {:noreply, workers_status}
  end

  defp check_workers_status() do
    CommonEmitter.publish(
      "",
      "{ \"type\": \"status\" }",
      [headers: [broadcast: "true"]],
      "direct_messaging"
    )

    interval =
      Application.get_env(:step_flow, StepFlow.Workers,
        workers_status_interval: @default_workers_status_interval
      )
      |> Keyword.get(:workers_status_interval, @default_workers_status_interval)

    Process.send_after(self(), :check, interval)
  end
end
