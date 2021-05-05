defmodule StepFlow.Router do
  use StepFlow, :router

  pipeline :api do
    plug(Plug.Parsers,
      parsers: [:json],
      pass: ["application/json"],
      json_decoder: Jason
    )
  end

  @version Mix.Project.config()[:version]

  pipe_through(:api)

  get("/", StepFlow.IndexController, :index)

  # Workflow definitiions APIs
  resources("/definitions", StepFlow.WorkflowDefinitionController,
    except: [:new, :edit, :delete, :update]
  )

  # Workflows APIs
  resources "/workflows", StepFlow.WorkflowController, except: [:new, :edit] do
    post("/events", StepFlow.WorkflowEventsController, :handle)
  end

  post("/launch_workflow", StepFlow.WorkflowController, :create)
  get("/workflows_statistics", StepFlow.WorkflowController, :statistics)

  # Jobs APIs
  get("/jobs", StepFlow.JobController, :index)

  # Workers APIs
  resources("/worker_definitions", StepFlow.WorkerDefinitionController,
    except: [:new, :edit, :delete, :update]
  )

  # Live Workers APIs
  get("/live_workers", StepFlow.LiveWorkersController, :index)

  # Metrics APIs
  get("/metrics", StepFlow.MetricController, :index)

  scope "/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :step_flow,
      swagger_file: "step_flow_swagger.json"
    )
  end

  get("/*path", StepFlow.IndexController, :not_found)

  def swagger_info do
    %{
      info: %{
        version: @version,
        title: "Step Flow"
      }
    }
  end
end
