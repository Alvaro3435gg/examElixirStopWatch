defmodule JswatchWeb.WatchUIChannel do
  use Phoenix.Channel
#inicia los genservers"
  def join("watch:ui", _message, socket) do
    GenServer.start_link(JswatchWeb.ClockManager, self())
    GenServer.start_link(JswatchWeb.IndigloManager, self())
    {:ok, socket}
  end
#si llega un evento, del front, lo manda al back
  def handle_in(event, _payload, socket) do
    :gproc.send({:p, :l, :ui_event}, String.to_atom(event))
    {:noreply, socket}
  end
#coloca el tiempo
  def handle_cast({:set_time_display, str}, socket) do
    push(socket, "setTimeDisplay", %{time: str})
    {:noreply, socket}
  end
#prende el indiglo
  def handle_cast(:set_indiglo, socket) do
    push(socket, "setIndiglo", %{})
    {:noreply, socket}
  end
#apaga el indiglo
  def handle_cast(:unset_indiglo, socket) do
    push(socket, "unsetIndiglo", %{})
    {:noreply, socket}
  end
end
