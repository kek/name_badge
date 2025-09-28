defmodule NameBadge.Screen.Weather do
  use NameBadge.Screen

  def render(%{}) do
    """
      #text(size: 36pt, font: "New Amsterdam")[Hello world]
    """
  end

  def init(_args, screen) do
    screen =
      screen
      |> assign(:foo, "bar")

    {:ok, assign(screen, :button_hints, %{a: "Next", b: "Go"})}
  end

  def handle_button("BTN_1", 0, screen) do
    {:render, screen}
    # {:norender, assign(screen, :sudo_mode, true)}
  end

  def handle_button("BTN_2", 0, screen) do
    {:render, navigate(screen, :back)}
  end

  def handle_button(_, _, screen) do
    {:norender, screen}
  end
end
