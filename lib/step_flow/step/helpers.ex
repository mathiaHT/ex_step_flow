defmodule StepFlow.Step.Helpers do
  @moduledoc """
  The Helper Step context.
  """

  @doc """
  Retrieve a value on an Object, filtered by the key
  """
  def get_value_in_parameters(object, key) do
    StepFlow.Map.get_by_key_or_atom(object, :parameters, [])
    |> Enum.filter(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :id) == key
    end)
    |> Enum.map(fn param ->
      StepFlow.Map.get_by_key_or_atom(
        param,
        :value,
        StepFlow.Map.get_by_key_or_atom(param, :default)
      )
    end)
  end

  @doc """
  Retrieve a value on an Object, filtered by the key and the type
  """
  def get_value_in_parameters_with_type(object, key, type) do
    StepFlow.Map.get_by_key_or_atom(object, :parameters, [])
    |> Enum.filter(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :id) == key &&
        StepFlow.Map.get_by_key_or_atom(param, :type) == type
    end)
    |> Enum.map(fn param ->
      StepFlow.Map.get_by_key_or_atom(
        param,
        :value,
        StepFlow.Map.get_by_key_or_atom(param, :default)
      )
    end)
  end

  def get_jobs_destination_paths(jobs) do
    jobs
    |> Enum.map(fn job ->
      get_job_destination_paths(job)
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.filter(fn path -> !is_nil(path) end)
  end

  def get_job_destination_paths(job) do
    destination_path = get_value_in_parameters(job, "destination_path")
    destination_paths = get_value_in_parameters(job, "destination_paths")

    destination_path ++ destination_paths
  end

  @doc """
  Filter a list of paths.

  ## Examples

      iex> StepFlow.Step.Helpers.filter_path_list(["path_1.ext1", "path2.ext2"], [%{"ends_with" => ".ext2"}])
      ["path2.ext2"]

      iex> StepFlow.Step.Helpers.filter_path_list(["path_1.ext1", "path2.ext2"], [%{ends_with: ".ext2"}])
      ["path2.ext2"]

  """
  def filter_path_list(source_paths, []), do: source_paths

  def filter_path_list(source_paths, [filter | filters]) do
    new_source_paths =
      case filter do
        %{ends_with: ends_with} ->
          Enum.filter(source_paths, fn path -> String.ends_with?(path, ends_with) end)

        %{"ends_with" => ends_with} ->
          Enum.filter(source_paths, fn path -> String.ends_with?(path, ends_with) end)
      end

    filter_path_list(new_source_paths, filters)
  end

  def get_step_requirements(jobs, step) do
    %{paths: get_required_paths(jobs, step)}
  end

  def get_required_paths(jobs, step) do
    required_ids = StepFlow.Map.get_by_key_or_atom(step, :required, [])

    jobs
    |> Enum.filter(fn job -> job.step_id in required_ids end)
    |> get_jobs_destination_paths
  end

  def add_required_paths(requirements, paths) when is_list(paths) do
    Map.update(requirements, :paths, paths, fn cur_paths ->
      Enum.concat(cur_paths, paths)
      |> Enum.uniq()
    end)
  end

  def add_required_paths(requirements, path) do
    paths =
      Map.get(requirements, :paths, [])
      |> List.insert_at(-1, path)

    add_required_paths(requirements, paths)
  end

  def get_dates do
    now = Timex.now()

    %{
      date_time: Timex.format!(now, "%Y_%m_%d__%H_%M_%S", :strftime),
      date: Timex.format!(now, "%Y_%m_%d", :strftime)
    }
  end

  def get_work_directory do
    System.get_env("WORK_DIR") ||
      Application.get_env(:step_flow, :work_dir) ||
      ""
  end

  def get_base_directory(workflow) do
    get_work_directory() <> "/" <> Integer.to_string(workflow.id) <> "/"
  end

  def templates_process([], _workflow, _dates, result), do: result

  def templates_process([template | templates], workflow, dates, result) do
    processed = intern_template_process(template, workflow, dates, [])
    result = List.insert_at(result, -1, processed)
    templates_process(templates, workflow, dates, result)
  end

  def template_process(template, workflow, dates, nil) do
    intern_template_process(template, workflow, dates, [])
  end

  def template_process(template, workflow, dates, source_path) when is_binary(source_path) do
    filename = Path.basename(source_path)
    extension = Path.extname(source_path)
    name = Path.basename(source_path, extension)

    source_keywords =
      Keyword.new()
      |> Keyword.put(:source_path, source_path)
      |> Keyword.put(:filename, filename)
      |> Keyword.put(:extension, extension)
      |> Keyword.put(:name, name)

    intern_template_process(template, workflow, dates, source_keywords)
  end

  def template_process(template, workflow, dates, source_paths) when is_list(source_paths) do
    source_keywords =
      Keyword.new()
      |> Keyword.put(:source_paths, source_paths)

    intern_template_process(template, workflow, dates, source_keywords)
  end

  defp intern_template_process(template, workflow, dates, source_keywords) do
    defined_parameters =
      workflow.parameters
      |> Enum.filter(fn item ->
        StepFlow.Map.get_by_key_or_atom(item, :type) in ["string", "array_of_strings"]
      end)
      |> Enum.map(fn item ->
        identifier =
          StepFlow.Map.get_by_key_or_atom(item, :id)
          |> String.to_atom()

        value =
          StepFlow.Map.get_by_key_or_atom(
            item,
            :value,
            StepFlow.Map.get_by_key_or_atom(item, :value)
          )

        {identifier, value}
      end)
      |> Keyword.put(:workflow_id, workflow.id)
      |> Keyword.put(:workflow_reference, workflow.reference)
      |> Keyword.put(:work_directory, get_work_directory())
      |> Keyword.put(:date_time, dates.date_time)
      |> Keyword.put(:date, dates.date)
      |> Keyword.merge(source_keywords)

    template
    |> String.replace("{", "<%= ")
    |> String.replace("}", " %>")
    |> EEx.eval_string(defined_parameters)
  end
end
