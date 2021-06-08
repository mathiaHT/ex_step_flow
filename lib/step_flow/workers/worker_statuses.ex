defmodule StepFlow.Workers.WorkerStatuses do
  @moduledoc """
  The WorkerStatuses context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.Workers.WorkerStatus

  @doc """
  Returns the list of WorkerStatuses.

  ## Examples

      iex> StepFlow.WorkerStatuses.list_worker_statuses()
      %{data: [], page: 0, size: 10, total: 0}

  """
  def list_worker_statuses(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force()

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force()

    offset = page * size

    query = from(worker_status in WorkerStatus)

    total_query = from(item in query, select: count(item.id))

    total =
      Repo.all(total_query)
      |> List.first()

    query =
      from(
        worker_status in query,
        order_by: [desc: :inserted_at],
        offset: ^offset,
        limit: ^size
      )

    worker_statuses = Repo.all(query)

    %{
      data: worker_statuses,
      total: total,
      page: page,
      size: size
    }
  end

  @doc false
  def process_worker_status_message(%{:job => job_status, :worker => worker_status}) do
    worker_status
    |> Map.put(:current_job, job_status)
  end

  @doc false
  def process_worker_status_message(%{"job" => job_status, "worker" => worker_status}) do
    worker_status
    |> Map.put("current_job", job_status)
  end

  @doc false
  def process_worker_status_message(%{:activity => activity} = message), do: message
  def process_worker_status_message(message) when message == %{}, do: message

  @doc """
  Gets a single WorkerStatus.

  Returns `nil` if the Worker does not exist.
  """
  def get_worker_status(instance_id) do
    Repo.get_by(WorkerStatus, instance_id: instance_id)
  end

  @doc """
  Gets a single WorkerStatus.

  Raises `Ecto.NoResultsError` if the WorkerStatus does not exist.
  """
  def get_worker_status!(instance_id) do
    Repo.get_by!(WorkerStatus, instance_id: instance_id)
  end

  @doc """
  Creates a WorkerStatus.

  ## Examples

      iex> result = StepFlow.Workers.WorkerStatuses.create_worker_status!(%{
      ...>    job: nil,
      ...>    worker: %{
      ...>      activity: "Idle",
      ...>      description: "This worker is just an example.",
      ...>      direct_messaging_queue_name: "direct_messaging_e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      ...>      instance_id: "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      ...>      label: "UnitTestWorker",
      ...>      queue_name: "job_test_worker",
      ...>      sdk_version: "2.3.4",
      ...>      short_description: "A test worker",
      ...>      system_info: %{
      ...>        docker_container_id: "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      ...>        number_of_processors: 12,
      ...>        total_memory: 16_574_754,
      ...>        total_swap: 2_046_816,
      ...>        used_memory: 8_865_633,
      ...>        used_swap: 0
      ...>      },
      ...>      version: "1.2.3"
      ...>    }
      ...> })
      ...> match?(%StepFlow.Workers.WorkerStatus{}, result)
      true

  Raises error if something went wrong during creation.
  """
  def create_worker_status!(%{} = message) do
    attrs =
      message
      |> process_worker_status_message

    %WorkerStatus{}
    |> WorkerStatus.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a WorkerStatus.

  ## Examples

      iex> result = StepFlow.Workers.WorkerStatuses.update_worker_status!(%{
      ...>    job: %{
      ...>      destination_paths: [],
      ...>      execution_duration: 0.0,
      ...>      job_id: 1234,
      ...>      parameters: [],
      ...>      status: "running"
      ...>    },
      ...>    worker: %{
      ...>      activity: "Idle",
      ...>      description: "This worker is just an example.",
      ...>      direct_messaging_queue_name: "direct_messaging_e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      ...>      instance_id: "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      ...>      label: "UnitTestWorker",
      ...>      queue_name: "job_test_worker",
      ...>      sdk_version: "2.3.4",
      ...>      short_description: "A test worker",
      ...>      system_info: %{
      ...>        docker_container_id: "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      ...>        number_of_processors: 12,
      ...>        total_memory: 16_574_754,
      ...>        total_swap: 2_046_816,
      ...>        used_memory: 8_865_633,
      ...>        used_swap: 0
      ...>      },
      ...>      version: "1.2.3"
      ...>    }
      ...> })
      ...> match?(%StepFlow.Workers.WorkerStatus{}, result)
      true

  Raises error if something went wrong during update.
  """
  def update_worker_status!(%WorkerStatus{} = worker_status, %{} = message) do
    attrs =
      message
      |> process_worker_status_message

    worker_status
    |> WorkerStatus.changeset(attrs)
    |> Repo.update!()
  end
end
