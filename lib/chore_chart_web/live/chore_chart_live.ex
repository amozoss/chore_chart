defmodule ChoreChartWeb.ChoreChartLive do
  use ChoreChartWeb, :live_view
  alias ChoreChart.Config

  @logout_timeout 10_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    socket =
      assign(socket,
        username: nil,
        password: "",
        logout_remaining: nil,
        current_time: DateTime.utc_now(),
        # Will store as %{"kid_name" => %{"chore_name" => true}}
        completed_chores: %{},
        secure_mouse: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      socket
      |> assign(current_time: DateTime.utc_now())
      |> update_logout_timer()

    {:noreply, socket}
  end

  @impl true
  def handle_event("key_press", %{"key" => key}, socket) do
    socket = handle_key_press(socket, key)
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_chore", %{"chore" => chore, "kid" => kid}, socket) do
    if can_toggle_chore?(socket) do
      socket =
        socket
        |> assign(username: kid)
        |> toggle_chore(kid, chore)
        |> reset_logout_timer()
        |> play_sound(if(completed_chore?(socket.assigns, kid, chore), do: "coin", else: "kick"))

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="chore-chart"
      phx-window-keydown="key_press"
      phx-throttle="100"
      id="chore-chart"
      phx-hook="Sound"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 p-4">
        <%= for {kid, info} <- Config.kids() do %>
          <div class="kid-section bg-white rounded-lg shadow-lg p-6">
            <div class="user-info mb-6" style={"color: #{info.color}"}>
              <div class="flex items-center gap-4">
                <img src={info.picture} alt={kid} class="w-16 h-16 rounded-full object-cover" />
                <h2 class="text-2xl font-bold capitalize">{kid}</h2>
              </div>
              <%= if @username == kid do %>
                <div class="logout-timer text-sm text-gray-500 mt-2">
                  Auto-logout in: {format_time_remaining(@logout_remaining)}
                </div>
              <% end %>
            </div>

            <div class="chores-grid grid grid-cols-1 sm:grid-cols-2 gap-4">
              <%= for {chore, index} <- Enum.with_index(Config.get_chores_for_day(kid), 1) do %>
                <div
                  class={"chore-item cursor-pointer p-4 rounded-lg transition-all #{if completed_chore?(assigns, kid, chore), do: "bg-green-100", else: "bg-gray-50"} hover:shadow-md"}
                  phx-click="toggle_chore"
                  phx-value-chore={chore}
                  phx-value-kid={kid}
                >
                  <div class="flex items-center gap-3">
                    <div class="chore-icon text-2xl">
                      {Config.chore_icons()[chore]}
                    </div>
                    <div class="flex-grow">
                      <div class="chore-name font-medium capitalize">
                        {chore}
                      </div>
                      <div class="text-sm text-gray-500">
                        Press {index} to toggle
                      </div>
                    </div>
                    <div class="chore-status text-xl">
                      <%= if completed_chore?(assigns, kid, chore) do %>
                        ✅
                      <% else %>
                        ⬜
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp handle_key_press(%{assigns: %{username: username}} = socket, key) do
    case Integer.parse(key) do
      {num, ""} when num >= 0 and num <= 9 ->
        num = if num == 0, do: 10, else: num
        kid = username || List.first(Map.keys(Config.kids()))
        chores = Config.get_chores_for_day(kid)

        if num <= length(chores) do
          chore = Enum.at(chores, num - 1)

          socket
          |> assign(username: kid)
          |> toggle_chore(kid, chore)
          |> reset_logout_timer()
          |> play_sound(
            if(completed_chore?(socket.assigns, kid, chore), do: "coin", else: "kick")
          )
        else
          socket
        end

      _ ->
        socket
    end
  end

  defp update_logout_timer(%{assigns: %{logout_remaining: nil}} = socket), do: socket

  defp update_logout_timer(socket) do
    if socket.assigns.logout_remaining <= 0 do
      socket
      |> assign(
        username: nil,
        password: "",
        logout_remaining: nil,
        completed_chores: %{}
      )
      |> play_sound("mariodie")
    else
      assign(socket, logout_remaining: socket.assigns.logout_remaining - 1000)
    end
  end

  defp reset_logout_timer(socket) do
    assign(socket, logout_remaining: @logout_timeout)
  end

  defp format_time_remaining(nil), do: ""

  defp format_time_remaining(ms) when is_integer(ms) do
    seconds = div(ms, 1000)
    "#{seconds}s"
  end

  defp toggle_chore(socket, kid, chore) do
    update(socket, :completed_chores, fn chores ->
      kid_chores = Map.get(chores, kid, %{})

      if Map.has_key?(kid_chores, chore) do
        Map.put(chores, kid, Map.delete(kid_chores, chore))
      else
        Map.put(chores, kid, Map.put(kid_chores, chore, true))
      end
    end)
  end

  defp completed_chore?(%{completed_chores: chores}, kid, chore) do
    chores
    |> Map.get(kid, %{})
    |> Map.has_key?(chore)
  end

  defp can_toggle_chore?(%{assigns: %{secure_mouse: true, username: username}}) do
    username != nil
  end

  defp can_toggle_chore?(_socket), do: true

  defp play_sound(socket, sound) do
    push_event(socket, "play_sound", %{sound: sound})
  end
end
