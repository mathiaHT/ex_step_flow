defmodule StepFlow.WorkersController do
  use StepFlow, :controller

  require Logger

  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Workers.WorkerStatuses

  action_fallback(StepFlow.FallbackController)

  def index(conn, params) do
    Logger.debug("[#{__MODULE__}] List worker statuses request: #{inspect(params)}")

    worker_statuses = WorkerStatuses.list_worker_statuses(params)

    conn
    |> put_view(StepFlow.WorkerStatusView)
    |> render("index.json", worker_statuses)
  end

  def show(conn, %{"id" => instance_id}) do
    Logger.debug("[#{__MODULE__}] Show worker status request: #{inspect(instance_id)}")

    worker_status = WorkerStatuses.get_worker_status(instance_id)

    conn
    |> put_view(StepFlow.WorkerStatusView)
    |> render("worker_status.json", %{worker_status: worker_status})
  end

  def update(conn, params) do
    Logger.debug("[#{__MODULE__}] Put order message request: #{inspect(params)}")

    instance_id = Map.get(params, "id")

    order_message =
      Map.delete(params, "id")
      |> Jason.encode!()

    Logger.info(
      "[#{__MODULE__}] Send order to worker #{inspect(instance_id)}: #{inspect(order_message)}"
    )

    CommonEmitter.publish(
      "",
      order_message,
      [headers: [instance_id: instance_id]],
      "direct_messaging"
    )

    conn
    |> send_resp(204, "")
  end
end
