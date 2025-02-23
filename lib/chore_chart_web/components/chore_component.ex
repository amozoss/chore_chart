defmodule ChoreChartWeb.ChoreComponent do
  use ChoreChartWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="chore-item">
      <div class="chore-icon">
        {ChoreChart.Config.chore_icons()[@chore]}
      </div>
      <div class="chore-name">
        {@chore}
      </div>
      <div class="chore-status">
        <%= if @completed do %>
          ✅
        <% else %>
          ⬜
        <% end %>
      </div>
    </div>
    """
  end
end
