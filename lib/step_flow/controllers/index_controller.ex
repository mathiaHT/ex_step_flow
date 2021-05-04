defmodule StepFlow.IndexController do
  use StepFlow, :controller
  use PhoenixSwagger

  action_fallback(ExBackendWeb.FallbackController)

  swagger_path :index do
    get("/")
    description("Home entrypoint for StepFlow")
    response(200, "Success")
  end

  def index(conn, _params) do
    {:ok, vsn} = :application.get_key(:step_flow, :vsn)

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(
      200,
      %{
        application: "Step Flow",
        version: "#{vsn}"
      }
      |> Jason.encode!()
    )
  end

  def not_found(conn, _params) do
    send_resp(conn, 404, "Not found")
  end
end
