defmodule ClientMonitor do
  use GenServer
  def init({list, start_time}), do: {:ok, {list, start_time}}
  def start_link({list, start_time}) do
    #IO.inspect(converage_remain)
    GenServer.start_link(__MODULE__, {list, start_time}, name: __MODULE__)
  end
  def handle_cast({:complete_msg, pid}, {list, start_time}) do
    list = List.delete(list, pid)
    if length(list) == 0 do
      end_time = System.monotonic_time(:microsecond)
      time_consumption = end_time - start_time
      IO.puts("Time Consumption: " <> to_string(time_consumption) <> "us = " <> to_string(div(time_consumption, 1000)) <> "ms.")
      Process.sleep(100)
      System.halt(0)
    end
    {:noreply, {list, start_time}}
  end

  def send_complete(pid) do
    GenServer.cast(__MODULE__, {:complete_msg, pid})
  end
end
