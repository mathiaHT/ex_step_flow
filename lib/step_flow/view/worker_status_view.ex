defmodule StepFlow.WorkerStatusView do
  use StepFlow, :view
  alias StepFlow.Workers.WorkerStatus
  alias StepFlow.WorkerStatusView

  def render("index.json", %{data: workers_status, total: total}) do
    %{
      data:
        render_many(workers_status, WorkerStatusView, "worker_status.json", as: :worker_status),
      total: total
    }
  end

  def render("worker_status.json", %{worker_status: worker_status}) do
    current_job =
      case worker_status.current_job do
        nil ->
          nil

        job_status ->
          %{
            job_id: job_status.job_id,
            status: job_status.status
          }
      end

    %{
      activity: worker_status.activity,
      current_job: current_job,
      description: worker_status.description,
      direct_messaging_queue_name: worker_status.direct_messaging_queue_name,
      instance_id: worker_status.instance_id,
      label: worker_status.label,
      queue_name: worker_status.queue_name,
      sdk_version: worker_status.sdk_version,
      short_description: worker_status.short_description,
      system_info: worker_status.system_info,
      version: worker_status.version
    }
  end
end
