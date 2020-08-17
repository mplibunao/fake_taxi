defmodule FakeTaxi do
  use GenServer

  @hook_templates "./lib/data.txt"

  def start_link(%{order_id: order_id, endpoint: endpoint, delivery_id: delivery_id}) do
    hooks =
      @hook_templates
      |> File.read!()
      |> Jason.decode!()
      |> Enum.reverse()
      |> Enum.map(fn data ->
        Map.put(data, "orderId", delivery_id)
      end)

    endpoint = "#{endpoint}/hooks/orkestro/#{order_id}"

    GenServer.start_link(FakeTaxi, %{hooks: hooks, endpoint: endpoint})
  end

  def cancel(%{
        order_id: order_id,
        delivery_id: delivery_id,
        endpoint: endpoint,
        vehicle_type: vehicle_type
      }) do
    endpoint = "#{endpoint}/hooks/orkestro/#{order_id}"

    send_request(
      %{
        "orderStatus" => "cancelled",
        "deliveryStatus" => "failed",
        "vehicleType" => vehicle_type,
        "deliveryId" => delivery_id
      },
      endpoint
    )
  end

  def schedule(%{order_id: order_id, delivery_id: delivery_id, endpoint: endpoint}) do
    endpoint = "#{endpoint}/hooks/orkestro/#{order_id}"

    send_request(
      %{
        "deliveryId" => delivery_id,
        "orderStatus" => "cancelled",
        "deliveryStatus" => "failed"
      },
      endpoint
    )
  end

  @impl true
  def init(state) do
    schedule_hook()
    {:ok, state}
  end

  @impl true
  def handle_info(:schedule_hook, %{hooks: [head | remaining], endpoint: endpoint} = _params) do
    send_request(head, endpoint)
    schedule_hook()
    {:noreply, %{hooks: remaining, endpoint: endpoint}}
  end

  @impl true
  def handle_info(:schedule_hook, state) do
    {:noreply, state}
  end

  def schedule_hook() do
    Process.send_after(self(), :schedule_hook, 1000)
  end

  defp send_request(request, endpoint) do
    case HTTPoison.post(endpoint, Jason.encode!(request), "Content-Type": "application/json") do
      {:ok, result} ->
        IO.puts(inspect(result))
        {:ok, result}

      {:error, error} ->
        IO.puts(inspect(error))
        {:ok, error}
    end
  end
end
