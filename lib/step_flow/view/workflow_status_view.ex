defmodule StepFlow.WorkflowStatusView do
  use StepFlow, :view
  alias StepFlow.WorkflowStatusView

  def render("state.json", %{workflow_status: status}) do
    %{
      id: status.id,
      state: status.state,
      inserted_at: status.inserted_at
    }
  end
end
