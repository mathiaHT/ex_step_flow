defmodule StepFlow.RunWorkflows.EmptyWorkflowTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  describe "workflows" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "empty_workflow",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [],
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ]
    }

    def workflow_fixture(workflow, attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(workflow)
        |> Workflows.create_workflow()

      workflow
    end

    test "run simple workflow without step" do
      workflow = workflow_fixture(@workflow_definition)
      {:ok, "completed"} = Step.start_next(workflow)
    end
  end
end
