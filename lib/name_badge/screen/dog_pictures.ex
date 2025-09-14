defmodule NameBadge.Screen.DogPictures do
  use NameBadge.Screen

  require Logger

  def render(_assigns) do
    """
    #place(center + horizon, stack(dir: ttb,
      v(48pt),
      text(size: 64pt, font: "New Amsterdam", "Dogs"))
    );
    """
  end

  def init(_args, screen) do
    {:ok, screen}
  end

  def handle_button(_, 0, screen) do
    {:render, navigate(screen, :back)}
  end

  def handle_button(_, _, screen) do
    {:norender, screen}
  end
end
