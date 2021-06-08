defmodule StepFlow.Migration.CreateWorkerStatus do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_worker_status) do
      add(:activity, :string, default: "")
      add(:description, :string, default: "")
      add(:direct_messaging_queue_name, :string)
      add(:instance_id, :string)
      add(:label, :string)
      add(:queue_name, :string)
      add(:sdk_version, :string, default: "")
      add(:short_description, :string, default: "")
      add(:system_info, :map, default: %{})
      add(:version, :string, default: "")
      add(:current_job, :map, default: nil)

      timestamps()
    end
  end
end
