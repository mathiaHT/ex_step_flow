defmodule StepFlow.Workers.WorkerStatusWatcher do
  require Logger

  @moduledoc false

  use GenServer
  alias StepFlow.Amqp.CommonEmitter

  def start_link(workers \\ %{}) do
    GenServer.start_link(__MODULE__, workers, name: __MODULE__)
  end

  def add_worker(id, worker) do
    GenServer.cast(__MODULE__, {:push, id, worker})
  end

  def get_worker(id) do
    GenServer.call(__MODULE__, :pop, id)
  end

  @impl true
  def init(workers) do
    Logger.info("[#{__MODULE__}] Start checking workers status!")

    check_workers_status()

    {:ok, workers}
  end

  @impl true
  def handle_info(:check, workers) do
    Logger.debug("[#{__MODULE__}] Check workers status. Current workers: #{inspect(workers)}")

    # Schedule once more
    check_workers_status()

    {:noreply, workers}
  end

  @impl true
  def handle_call(:pop, _from, id, workers) do
    Logger.debug("[#{__MODULE__}] Get worker #{id} status from : #{inspect(workers)}")
    worker = Map.get(workers, id)
    {:reply, nil, workers}
  end

  @impl true
  def handle_cast({:push, id, worker}, workers) do
    Logger.debug("[#{__MODULE__}] Add #{id} worker to workers status: #{inspect(worker)}")
    workers = Map.put(workers, id, worker)

    Logger.debug(
      "[#{__MODULE__}] Notify that workers status have been updated: #{inspect(workers)}"
    )

    StepFlow.Notification.send("workers_status_updated", %{content: workers})

    {:noreply, workers}
  end

  defp check_workers_status() do
    CommonEmitter.publish(
      "",
      "{ \"type\": \"status\" }",
      [headers: [broadcast: "true"]],
      "direct_messaging"
    )

    Process.send_after(self(), :check, 10 * 1000)
  end
end
