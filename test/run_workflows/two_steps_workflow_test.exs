defmodule StepFlow.RunWorkflows.TwoStepsWorkflowTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    channel = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_queue_not_found", 2)
    end)

    :ok
  end

  describe "workflows" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Two steps workflow",
      tags: ["test"],
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: ["my_file.mov"]
            }
          ]
        },
        %{
          id: 1,
          name: "my_second_step",
          icon: "step_icon",
          label: "My second step",
          parent_ids: [0],
          required_to_start: [0],
          parameters: []
        }
      ],
      parameters: [],
      rights: [
        %{
          action: "view",
          groups: []
        }
      ]
    }

    test "run simple workflow with 2 steps" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "started"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 2)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)
      StepFlow.HelpersTest.check(workflow.id, "my_second_step", 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_second_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 2)
    end
  end
end
