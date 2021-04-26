defmodule StepFlow.Migration.ModifyWorkflowStatus do
  use Ecto.Migration
  @moduledoc false

  def change do
    drop_if_exists(table(:step_flow_workflow_status))

    create table(:step_flow_workflow_status) do
      add(:state, :string)
      add(:status_id, references(:step_flow_status, on_delete: :nothing), null: true)
      add(:workflow_id, references(:step_flow_workflow, on_delete: :nothing))

      timestamps()
    end

    create(index(:step_flow_workflow_status, [:workflow_id]))
  end
end
