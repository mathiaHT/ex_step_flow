defmodule StepFlow.Jobs.Status do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  alias StepFlow.Jobs.Job
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo
  require Logger

  @moduledoc false

  defenum(StateEnum, ["queued", "skipped", "processing", "retrying", "error", "completed"])

  def state_enum_label(value) do
    case value do
      value when value in [0, :queued] -> "queued"
      value when value in [1, :skipped] -> "skipped"
      value when value in [2, :processing] -> "processing"
      value when value in [3, :retrying] -> "retrying"
      value when value in [4, :error] -> "error"
      value when value in [5, :completed] -> "completed"
      _ -> "unknown"
    end
  end

  schema "step_flow_status" do
    field(:state, StepFlow.Jobs.Status.StateEnum)
    field(:description, :map, default: %{})
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps()
  end

  @doc false
  def changeset(%Status{} = job, attrs) do
    job
    |> cast(attrs, [:state, :job_id, :description])
    |> foreign_key_constraint(:job_id)
    |> validate_required([:state, :job_id])
  end

  def set_job_status(job_id, status, description \\ %{}) do
    %Status{}
    |> Status.changeset(%{job_id: job_id, state: status, description: description})
    |> Repo.insert()
  end

  @doc """
  Returns the last updated status of a list of status.
  """
  def get_last_status(status) when is_list(status) do
    status
    |> Enum.sort(fn state_1, state_2 ->
      state_1.updated_at < state_2.updated_at
    end)
    |> List.last()
  end

  def get_last_status(%Status{} = status), do: status
  def get_last_status(_status), do: nil

  @doc """
  Returns the relevant status of a list of status.
  """
  def get_status(job) do
    count_completed =
      job.status
      |> Enum.filter(fn s -> s.state == :completed end)
      |> length

    # A job with at least one status.state at :completed is considered :completed
    if count_completed >= 1 do
      :completed
    else
      last_progression =
        job.progressions
        |> Progression.get_last_progression()

      last_status =
        job.status
        |> get_last_status()

      Logger.warn(last_status)

      case {last_status, last_progression} do
        {last_status, _} when last_status.state == :error ->
          :error

        {last_status, _} when last_status.state == :skipped ->
          :skipped

        {nil, nil} ->
          :queued

        {last_status, []} when last_status.state == :retrying ->
          :queued

        {nil, _} ->
          :processing

        {last_status, last_progression}
        when last_progression.updated_at > last_status.updated_at ->
          :processing

        {_, _} ->
          nil
      end
    end
  end
end
