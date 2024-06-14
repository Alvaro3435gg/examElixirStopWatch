defmodule JswatchWeb.IndigloManager do
  use GenServer
#inicializa sin luz, sin contadores y sin timers
  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    {:ok, %{ui_pid: ui, st: IndigloOff, count: 0, timer1: nil, time2: nil, alarm: false}}
  end

  #si aprieta top right y esta apagado, lo prende
  def handle_info(:"top-right-pressed", %{ui_pid: pid, st: IndigloOff} = state) do
    GenServer.cast(pid, :set_indiglo)
    {:noreply, %{state | st: IndigloOn}}
  end

  #suelta top right y está prendido, y manda a esperar 2 secs y se pone a eseperar
  def handle_info(:"top-right-released", %{st: IndigloOn} = state) do
    timer = Process.send_after(self(), Waiting_IndigloOff, 2000)
    {:noreply, %{state | st: Waiting, timer1: timer}}
  end

  #si se aprieta, llama a poner una alarma en 5 secs
  def handle_info(:"top-left-pressed", state) do
    :gproc.send({:p, :l, :ui_event}, :update_alarm)
    {:noreply, state}
  end

  #si  si ya esperó los 2 secs y está esperando, apaga el indiglo
  def handle_info(Waiting_IndigloOff, %{ui_pid: pid, st: Waiting} = state) do
    GenServer.cast(pid, :unset_indiglo)
    {:noreply, %{state| st: IndigloOff}}
  end

  #recibe la instrucción de empezar alarma, y si está apagado, manda a esperar medio segundo y se queda en alarma prendida
  def handle_info(:start_alarm, %{ui_pid: pid, st: IndigloOff} = state) do
    Process.send_after(self(), AlarmOn_AlarmOff, 500)
    GenServer.cast(pid, :set_indiglo)
    {:noreply, %{state | count: 49, st: AlarmOn}}
  end
 #recibe la instrucción de empezar alarma, y si está prendido, manda a espera medio segundo, y se queda en alarma apagada
  def handle_info(:start_alarm, %{st: IndigloOn} = state) do
    Process.send_after(self(), AlarmOff_AlarmOn, 500)
    {:noreply, %{state | count: 49, st: AlarmOff}}
  end
#si ya está esprando para apagarse la luz, pero se aprieta, va a ponerse a de igual forma la alarma
  def handle_info(Waiting_IndigloOff, %{ui_pid: pid, st: Waiting, timer1: timer} = state) do
    if timer != nil do
      Process.cancel_timer(timer)
    end
    GenServer.cast(pid, :unset_indiglo)
    Process.send_after(self(), AlarmOff_AlarmOn, 500)

    {:noreply, %{state| count: 50, timer1: nil, st: AlarmOff}}
  end

#si la alarma está activa, y está encendida, si el contador no ha llegado a uno lo apaga y resta al contador, si no, quita contador y apaga
  def handle_info(AlarmOn_AlarmOff, %{ui_pid: pid, count: count, st: AlarmOn} = state) do
    if count >= 1 do
      Process.send_after(self(), AlarmOff_AlarmOn, 500)
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: count - 1, st: AlarmOff}}
    else
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: 0, st: IndigloOff}}
    end

  end

  #si la alarma está activa y está apagada, si el contador no ha llegado a uno lo enciende y resta al contador, si no, quita el contador y apaga
  def handle_info(AlarmOff_AlarmOn, %{ui_pid: pid, count: count, st: AlarmOff} = state) do
    if count >= 1 do
      Process.send_after(self(), AlarmOn_AlarmOff, 500)
      GenServer.cast(pid, :set_indiglo)
      {:noreply, %{state | count: count - 1, st: AlarmOn}}
    else
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: 0, st: IndigloOff}}
    end
  end



  def handle_info(:"bottom-right-pressed", %{ui_pid: pid, st: AlarmOn} = state) do
    GenServer.cast(pid, :unset_indiglo)
    Process.send_after(self(), Wait2Stop, 2000)
    {:noreply, %{state | st: IndigloOff}}
  end

  def handle_info(:"bottom-right-pressed", %{ui_pid: pid, st: AlarmOff} = state) do
    GenServer.cast(pid, :unset_indiglo)
    Process.send_after(self(), Wait2Stop, 2000)
    {:noreply, %{state | st: IndigloOff}}
  end

  def handle_info(Wait2Stop, %{st: IndigloOff} = state) do
    {:noreply, %{state | alarm: true}}
  end

  def handle_info(:"bottom-right-released", %{alarm: true} = state) do
    :gproc.send({:p, :l, :ui_event}, :update_alarm)
    {:noreply, %{state | alarm: false}}
  end

  def handle_info(:"bottom-right-released", %{alarm: false} = state) do
    {:noreply, %{state | alarm: false}}
  end


  #este es mi intento de snoze



    #imprime el evento pero maneja en caso de que se metan otros estados
  def handle_info(event, state) do
    IO.inspect(event)
    {:noreply, state}
  end

end
