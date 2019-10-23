defmodule StepFlow.Api.WorkflowsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  test "GET /" do
    {status, _headers, body} =
      conn(:get, "/")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body == "Welcome to Step Flow"
  end

  test "GET /unknown" do
    {status, _headers, body} =
      conn(:get, "/unknown")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 404
    assert body == "Not found"
  end

  # test "GET /workflows/00000000-0000-0000-0000-000000000000" do
  #   {status, _headers, body} =
  #     conn(:get, "/workflows/00000000-0000-0000-0000-000000000000")
  #     |> Router.call(@opts)
  #     |> sent_resp

  #   assert status == 200
  #   assert body |> Jason.decode!() == %{}
  # end

  test "GET /workflows" do
    {status, _headers, body} =
      conn(:get, "/workflows")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body |> Jason.decode!() == %{"data" => [], "total" => 0}

    {status, _headers, _body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    {status, _headers, body} =
      conn(:get, "/workflows")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body |> Jason.decode!() |> Map.get("total") == 1
  end

  test "POST /workflows invalid" do
    {status, _headers, body} =
      conn(:post, "/workflows", %{})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 422

    assert body |> Jason.decode!() == %{
             "errors" => %{
               "identifier" => ["can't be blank"],
               "reference" => ["can't be blank"],
               "version_major" => ["can't be blank"],
               "version_micro" => ["can't be blank"],
               "version_minor" => ["can't be blank"]
             }
           }
  end

  test "POST /workflows valid" do
    {status, _headers, _body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201
  end

  test "SHOW /workflows/:id" do
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    {status, _headers, body} =
      conn(:get, "/workflows/" <> workflow_id)
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    data =
      body
      |> Jason.decode!()
      |> Map.get("data")

    identifier =
      data
      |> Map.get("identifier")

    assert identifier == "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"

    reference =
      data
      |> Map.get("reference")

    assert reference == "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"
  end

  test "UPDATE /workflows/:id" do
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    {status, _headers, body} =
      conn(:put, "/workflows/" <> workflow_id, %{workflow: %{reference: "updated reference"}})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    reference =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("reference")

    assert reference == "updated reference"
  end

  test "DELETE /workflows/:id" do
    {status, _headers, body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    {status, _headers, body} =
      conn(:delete, "/workflows/" <> workflow_id)
      |> Router.call(@opts)
      |> sent_resp

    assert status == 204
    assert body == ""
  end

  test "GET /workflows/statistics" do
    {status, _headers, body} =
      conn(:get, "/workflows/statistics")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    assert body |> Jason.decode!() |> Map.get("data") |> length == 50
  end
end
