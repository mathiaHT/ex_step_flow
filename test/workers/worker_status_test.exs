defmodule StepFlow.Workers.WorkerStatusTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Workers.WorkerStatuses

  doctest StepFlow

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

  @worker_status_without_job_2 %{
    "job" => nil,
    "type" => "status",
    "worker" => %{
      "activity" => "Idle",
      "description" => "This worker is just an example.",
      "direct_messaging_queue_name" => "direct_messaging_e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      "instance_id" => "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
      "label" => "UnitTestWorker",
      "queue_name" => "job_test_worker",
      "sdk_version" => "2.3.4",
      "short_description" => "A test worker",
      "system_info" => %{
        "docker_container_id" => "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
        "number_of_processors" => 12,
        "total_memory" => 16_574_754,
        "total_swap" => 2_046_816,
        "used_memory" => 8_865_633,
        "used_swap" => 0
      },
      "version" => "1.2.3"
    }
  }

  @worker_status_without_instance_id %{
    job: nil,
    type: "status",
    worker: %{
      activity: "Idle",
      system_info: %{
        docker_container_id: "2856099cee46",
        number_of_processors: 12,
        total_memory: 33_619_046,
        total_swap: 2_147_479,
        used_memory: 5_581_515,
        used_swap: 0
      }
    }
  }

  @worker_status_without_instance_id_2 %{
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

  test "process worker status message without job" do
    result = WorkerStatuses.process_worker_status_message(@worker_status_without_job)

    assert result == %{
             activity: "Idle",
             current_job: nil,
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
  end

  test "process worker status message without job 2" do
    result = WorkerStatuses.process_worker_status_message(@worker_status_without_job_2)

    assert result == %{
             "activity" => "Idle",
             "current_job" => nil,
             "description" => "This worker is just an example.",
             "direct_messaging_queue_name" =>
               "direct_messaging_e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
             "instance_id" => "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
             "label" => "UnitTestWorker",
             "queue_name" => "job_test_worker",
             "sdk_version" => "2.3.4",
             "short_description" => "A test worker",
             "system_info" => %{
               "docker_container_id" => "e1297fe6-fe94-49cf-9ef8-1a751cba28f2",
               "number_of_processors" => 12,
               "total_memory" => 16_574_754,
               "total_swap" => 2_046_816,
               "used_memory" => 8_865_633,
               "used_swap" => 0
             },
             "version" => "1.2.3"
           }
  end

  test "process worker status message without instance_id" do
    result = WorkerStatuses.process_worker_status_message(@worker_status_without_instance_id)

    assert result == %{
             activity: "Idle",
             current_job: nil,
             instance_id: "2856099cee46",
             system_info: %{
               docker_container_id: "2856099cee46",
               number_of_processors: 12,
               total_memory: 33_619_046,
               total_swap: 2_147_479,
               used_memory: 5_581_515,
               used_swap: 0
             }
           }
  end

  test "process worker status message without instance_id 2" do
    result = WorkerStatuses.process_worker_status_message(@worker_status_without_instance_id_2)

    assert result == %{
             "activity" => "Busy",
             "current_job" => %{
               "job_id" => 38,
               "status" => "initialized",
               "destination_paths" => [],
               "execution_duration" => 4.6e-8,
               "parameters" => []
             },
             "instance_id" => "2856099cee46",
             "system_info" => %{
               "docker_container_id" => "2856099cee46",
               "number_of_processors" => 12,
               "total_memory" => 33_619_046,
               "total_swap" => 2_147_479,
               "used_memory" => 5_581_515,
               "used_swap" => 0
             }
           }
  end

  test "create and get worker status structure without job" do
    worker_status = WorkerStatuses.create_worker_status!(@worker_status_without_job)

    assert worker_status.instance_id == "e1297fe6-fe94-49cf-9ef8-1a751cba28f2"

    assert worker_status.direct_messaging_queue_name ==
             "direct_messaging_" <> "e1297fe6-fe94-49cf-9ef8-1a751cba28f2"

    assert worker_status.current_job == nil

    worker_status = WorkerStatuses.get_worker_status(worker_status.instance_id)

    assert worker_status.instance_id == "e1297fe6-fe94-49cf-9ef8-1a751cba28f2"

    assert worker_status.direct_messaging_queue_name ==
             "direct_messaging_" <> "e1297fe6-fe94-49cf-9ef8-1a751cba28f2"

    worker_statuses =
      WorkerStatuses.list_worker_statuses()
      |> Map.get(:data)

    assert Enum.count(worker_statuses) == 1
    assert List.first(worker_statuses) == worker_status

    updated_worker_status = WorkerStatuses.update_worker_status!(worker_status, %{})

    assert updated_worker_status == worker_status
  end

  test "create and get worker status structure with job" do
    worker_status = WorkerStatuses.create_worker_status!(@worker_status_without_job)

    assert worker_status.instance_id == "e1297fe6-fe94-49cf-9ef8-1a751cba28f2"

    assert worker_status.direct_messaging_queue_name ==
             "direct_messaging_" <> "e1297fe6-fe94-49cf-9ef8-1a751cba28f2"

    update = %{
      job: %{
        destination_paths: [],
        execution_duration: 0.000001091,
        job_id: 1234,
        parameters: [],
        status: "running"
      },
      type: "status",
      worker: %{
        activity: "Busy",
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
          used_memory: 12_448_924,
          used_swap: 0
        },
        version: "1.2.3"
      }
    }

    updated_worker_status = WorkerStatuses.update_worker_status!(worker_status, update)

    worker_status = WorkerStatuses.get_worker_status(worker_status.instance_id)

    assert worker_status.id == updated_worker_status.id
    assert worker_status.instance_id == updated_worker_status.instance_id

    assert worker_status.direct_messaging_queue_name ==
             updated_worker_status.direct_messaging_queue_name

    assert updated_worker_status.current_job.job_id == 1234
    assert updated_worker_status.current_job.status == :running

    worker_statuses =
      WorkerStatuses.list_worker_statuses()
      |> Map.get(:data)

    assert Enum.count(worker_statuses) == 1
    assert List.first(worker_statuses) == worker_status
  end

  test "create and get worker status structure without instance_id" do
    worker_status = WorkerStatuses.create_worker_status!(@worker_status_without_instance_id)

    assert worker_status.instance_id == "2856099cee46"

    update = %{
      job: %{
        destination_paths: [],
        execution_duration: 4.6e-8,
        job_id: 38,
        parameters: [],
        status: "initialized"
      },
      type: "status",
      worker: %{
        activity: "Busy",
        system_info: %{
          docker_container_id: "2856099cee46",
          number_of_processors: 12,
          total_memory: 33_619_046,
          total_swap: 2_147_479,
          used_memory: 5_581_515,
          used_swap: 0
        }
      }
    }

    updated_worker_status = WorkerStatuses.update_worker_status!(worker_status, update)

    worker_status = WorkerStatuses.get_worker_status(worker_status.instance_id)

    assert worker_status.id == updated_worker_status.id
    assert worker_status.instance_id == updated_worker_status.instance_id

    assert updated_worker_status.current_job.job_id == 38
    assert updated_worker_status.current_job.status == :initialized

    worker_statuses =
      WorkerStatuses.list_worker_statuses()
      |> Map.get(:data)

    assert Enum.count(worker_statuses) == 1
    assert List.first(worker_statuses) == worker_status
  end
end
