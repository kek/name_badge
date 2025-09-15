import Config

# Test configuration for running tests on host

# Set required environment variables for testing
System.put_env("BASE_URL", "http://localhost:4000")

# Override tzdata config for testing
config :tzdata, :data_dir, System.tmp_dir!()

# Set base_url for testing
config :name_badge, :base_url, "http://localhost:4000"

# Mock modules for testing
config :name_badge, :mock_modules, true

# Mock EInk module
defmodule EInk do
  def new(_driver, _opts) do
    {:ok, :mock_eink}
  end

  def clear(_eink, _color) do
    :ok
  end

  def draw(_eink, _image, _opts \\ []) do
    :ok
  end

  defmodule Driver do
    defmodule UC8276 do
    end
  end
end

# Mock Circuits.GPIO module
defmodule Circuits.GPIO do
  def open(_pin, _direction) do
    {:ok, :mock_gpio}
  end

  def set_interrupts(_gpio, _trigger) do
    :ok
  end
end

# Mock VintageNet module
defmodule VintageNet do
  def subscribe(_property) do
    :ok
  end

  def get(_property) do
    :internet
  end
end

# Mock Nerves.Runtime.KV module
defmodule Nerves.Runtime.KV do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def get(key) do
    case key do
      "nerves_fw_active" -> "a"
      "a.nerves_fw_version" -> "0.0.0"
      "a.nerves_fw_uuid" -> "12345678-1234-1234-1234-123456789abc"
      "b.nerves_fw_version" -> "0.0.0"
      "b.nerves_fw_uuid" -> "87654321-4321-4321-4321-cba987654321"
      _ -> nil
    end
  end
end
