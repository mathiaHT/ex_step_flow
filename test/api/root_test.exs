defmodule StepFlow.Api.RootTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  test "GET /" do
    {status, _headers, body} =
      conn(:get, "/")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    assert %{
             "application" => "Step Flow",
             "version" => _version
           } = body |> Jason.decode!()
  end

  test "GET /unknown" do
    {status, _headers, body} =
      conn(:get, "/unknown")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 404
    assert body == "Not found"
  end
end
