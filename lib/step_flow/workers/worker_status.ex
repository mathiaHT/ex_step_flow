defmodule StepFlow.Workers.WorkerStatus do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  alias StepFlow.Jobs.Status
  alias StepFlow.Workers.WorkerStatus

  @moduledoc false

  defenum(ActivityEnum, [
    "Idle",
    "Busy",
    "Suspended",
    "Terminated"
  ])

  schema "step_flow_worker_status" do
    field(:activity, ActivityEnum, default: "Idle")
    field(:description, :string, default: "")
    field(:direct_messaging_queue_name, :string, default: "")
    field(:instance_id, :string)
    field(:label, :string, default: "")
    field(:queue_name, :string, default: "")
    field(:sdk_version, :string, default: "")
    field(:short_description, :string, default: "")
    field(:system_info, :map, default: %{})
    field(:version, :string, default: "")

    embeds_one :current_job, JobStatus, on_replace: :delete do
      field(:job_id, :integer)
      field(:status, Status.StateEnum)
    end

    timestamps()
  end

  @doc false
  def changeset(%WorkerStatus{} = worker_status, attrs) do
    worker_status
    |> cast(attrs, [
      :activity,
      :description,
      :direct_messaging_queue_name,
      :instance_id,
      :label,
      :queue_name,
      :sdk_version,
      :short_description,
      :system_info,
      :version
    ])
    |> cast_embed(:current_job, with: &job_status_changeset/2)
    |> validate_required([
      :instance_id
    ])
    |> unique_constraint(:instance_id)
  end

  defp job_status_changeset(schema, params) do
    schema
    |> cast(params, [
      :job_id,
      :status
    ])
    |> validate_required([
      :job_id,
      :status
    ])
  end
end
