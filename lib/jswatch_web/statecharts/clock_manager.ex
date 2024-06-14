defmodule JswatchWeb.ClockManager do
  use GenServer

  #inicializa el clock manager con el time y la alarma, pone alarma en 10 segs y inicia el proceso del reloj con working working
  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    {_, now} = :calendar.local_time()
    time = Time.from_erl!(now)
    alarm = Time.add(time, 10)
    Process.send_after(self(), :working_working, 1000)
    {:ok, %{ui_pid: ui, time: time, alarm: alarm, st: Working}}
  end

#pone una alarma en 5 segundos
  def handle_info(:update_alarm, state) do
    {_, now} = :calendar.local_time()
    time = Time.from_erl!(now)
    alarm = Time.add(time, 5)
    {:noreply, %{state | alarm: alarm}}
  end

#es el proceso del reloj, y además si el tiempo llega a una alarma establecida, imprime alarma y manda a empezar alarma
  def handle_info(:working_working, %{ui_pid: ui, time: time, alarm: alarm, st: Working} = state) do
    Process.send_after(self(), :working_working, 1000)
    time = Time.add(time, 1)
    if time == alarm do
      IO.puts("ALARM!!!")
      :gproc.send({:p, :l, :ui_event}, :start_alarm)
    end
    GenServer.cast(ui, {:set_time_display, Time.truncate(time, :second) |> Time.to_string })
    {:noreply, state |> Map.put(:time, time) }
  end

  #si en caso de que no resiva algo que conoce
  def handle_info(_event, state), do: {:noreply, state}
end
