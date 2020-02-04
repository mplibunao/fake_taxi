defmodule FakeTaxi do
  use GenServer

  @hook_templates "./lib/data.txt"

  def start_link(%{order_id: order_id, endpoint: endpoint}) do
    hooks =
      @hook_templates
      |> File.read!()
      |> Jason.decode!()
      |> Enum.reverse()
    endpoint = "#{endpoint}/hooks/orkestro/#{order_id}"

    GenServer.start_link(FakeTaxi, %{hooks: hooks, endpoint: endpoint})
  end

  @impl true
  def init(state) do
    schedule_hook()
    {:ok, state}
  end

  def handle_info(:schedule_hook, %{hooks: [head | remaining], endpoint: endpoint} = params) do
    send_request(head, endpoint)
    schedule_hook()
    {:noreply, %{hooks: remaining, endpoint: endpoint}}
  end

  def handle_info(:schedule_hook, state) do
    {:noreply, state}
  end

  def schedule_hook() do
    Process.send_after(self(), :schedule_hook, 1000)
  end

  defp send_request(request, endpoint) do
    case HTTPoison.post(endpoint, Jason.encode!(request), ["Content-Type": "application/json"]) do
      {:ok, result} ->
        IO.puts inspect result
        {:ok, result}
      {:error, error} ->
        IO.puts inspect error
        {:ok, error}
    end
  end
end
