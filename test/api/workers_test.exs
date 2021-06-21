defmodule StepFlow.WorkersTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Workers.WorkerStatuses
  alias StepFlow.Router

  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    {conn, _channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.close_amqp_connection(conn)
    end)
  end

  @worker_status_without_job %{
    job: nil,
    type: "status",
    worker: %{
      activity: "Idle",
      description: "This worker is just an example.",
      direct_messaging_queue_name: "direct_messaging_e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      instance_id: "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      label: "UnitTestWorker",
      queue_name: "job_test_worker",
      sdk_version: "2.3.4",
      short_description: "A test worker",
      system_info: %{
        docker_container_id: "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
        number_of_processors: 12,
        total_memory: 16_574_754,
        total_swap: 2_046_816,
        used_memory: 8_865_633,
        used_swap: 0
      },
      version: "1.2.3"
    }
  }

  @worker_status_with_job_but_no_instance_id %{
    "job" => %{
      "destination_paths" => [],
      "execution_duration" => 4.6e-8,
      "job_id" => 38,
      "parameters" => [],
      "status" => "initialized"
    },
    "type" => "status",
    "worker" => %{
      "activity" => "Busy",
      "system_info" => %{
        "docker_container_id" => "2856099cee46",
        "number_of_processors" => 12,
        "total_memory" => 33_619_046,
        "total_swap" => 2_147_479,
        "used_memory" => 5_581_515,
        "used_swap" => 0
      }
    }
  }

  test "create and get worker status" do
    WorkerStatuses.create_worker_status!(@worker_status_without_job)

    expected_response_body =
      WorkerStatuses.process_worker_status_message(@worker_status_without_job)
      |> Jason.encode!()

    {status, _headers, body} =
      conn(:get, "/workers/e1297fe6-fe94-49cf-9ef8-1a751cba28f2")
      |> assign(:current_user, %{rights: ["user_view"]})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body == expected_response_body
  end

  test "create and list worker statuses" do
    WorkerStatuses.create_worker_status!(@worker_status_without_job)

    processed_worker_status_without_job =
      WorkerStatuses.process_worker_status_message(@worker_status_without_job)

    WorkerStatuses.create_worker_status!(@worker_status_with_job_but_no_instance_id)

    processed_worker_status_with_job_but_no_instance_id = %{
      "current_job" => %{
        "job_id" => 38,
        "status" => "initialized"
      },
      "activity" => "Busy",
      "description" => "",
      "direct_messaging_queue_name" => "",
      "instance_id" => "2856099cee46",
      "label" => "",
      "queue_name" => "",
      "sdk_version" => "",
      "short_description" => "",
      "system_info" => %{
        "docker_container_id" => "2856099cee46",
        "number_of_processors" => 12,
        "total_memory" => 33_619_046,
        "total_swap" => 2_147_479,
        "used_memory" => 5_581_515,
        "used_swap" => 0
      },
      "version" => ""
    }

    expected_response_body =
      %{
        data: [
          processed_worker_status_without_job,
          processed_worker_status_with_job_but_no_instance_id
        ],
        total: 2
      }
      |> Jason.encode!()

    {status, _headers, body} =
      conn(:get, "/workers")
      |> assign(:current_user, %{rights: ["user_view"]})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body == expected_response_body
  end
end
