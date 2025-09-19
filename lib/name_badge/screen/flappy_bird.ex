defmodule NameBadge.Screen.FlappyBird do
  use NameBadge.Screen

  require Logger

  @gravity 15  # Much larger gravity for slow refresh
  @jump_force -50  # Much larger jump force
  @pipe_width 50
  @pipe_gap 120  # Larger gap for easier gameplay
  @pipe_speed 80  # Much faster pipe movement per frame
  @bird_size 25

  def render(%{game_state: :playing, bird: bird, pipes: pipes, score: score}) do
    # Render bird using positioned rect
    bird_element = "#place(left + top, dx: #{bird.x}pt, dy: #{bird.y}pt, rect(width: #{@bird_size}pt, height: #{@bird_size}pt, fill: yellow))"
    
    # Render pipes using positioned rects
    pipe_elements = 
      pipes
      |> Enum.map(fn pipe ->
        top_pipe_height = pipe.y
        bottom_pipe_y = pipe.y + @pipe_gap
        bottom_pipe_height = 300 - bottom_pipe_y
        
        """
        #place(left + top, dx: #{pipe.x}pt, dy: 0pt, rect(width: #{@pipe_width}pt, height: #{top_pipe_height}pt, fill: green)),
        #place(left + top, dx: #{pipe.x}pt, dy: #{bottom_pipe_y}pt, rect(width: #{@pipe_width}pt, height: #{bottom_pipe_height}pt, fill: green))
        """
      end)
      |> Enum.join(",\n")
    
    # Render score
    score_element = "#place(top + left, dx: 20pt, dy: 20pt, text(size: 24pt, font: \"New Amsterdam\", \"Score: #{score}\"))"
    
    """
    #{score_element};
    #{bird_element};
    #{pipe_elements};
    """
  end

  def render(%{game_state: :game_over, score: score, high_score: high_score}) do
    """
    #place(center + horizon,
      stack(dir: ttb, spacing: 16pt,
        text(size: 48pt, font: "New Amsterdam", "Game Over!"),
        text(size: 24pt, font: "New Amsterdam", "Score: #{score}"),
        text(size: 24pt, font: "New Amsterdam", "High Score: #{high_score}"),
        text(size: 20pt, font: "New Amsterdam", "Press A to restart"),
        text(size: 20pt, font: "New Amsterdam", "Press B to exit")
      )
    );
    """
  end

  def render(%{game_state: :start}) do
    """
    #place(center + horizon,
      stack(dir: ttb, spacing: 16pt,
        text(size: 48pt, font: "New Amsterdam", "Flappy Bird"),
        text(size: 20pt, font: "New Amsterdam", "Slow-paced version"),
        text(size: 24pt, font: "New Amsterdam", "Press A to start"),
        text(size: 20pt, font: "New Amsterdam", "Press B to exit")
      )
    );
    """
  end

  def init(_args, screen) do
    initial_state = %{
      game_state: :start,
      bird: %{x: 80, y: 150, velocity: 0},
      pipes: [],
      score: 0,
      high_score: 0,
      pipe_timer: 0,
      game_timer: 0
    }

    {:ok, assign(screen, :button_hints, %{a: "Jump/Start", b: "Exit"}) |> Map.put(:assigns, Map.merge(screen.assigns, initial_state))}
  end

  def handle_button("BTN_1", 0, %{assigns: %{game_state: :start}} = screen) do
    new_state = start_game(screen.assigns)
    screen = %{screen | assigns: Map.merge(screen.assigns, new_state)}
    schedule_game_tick()
    {:render, screen}
  end

  def handle_button("BTN_1", 0, %{assigns: %{game_state: :playing}} = screen) do
    new_bird = %{screen.assigns.bird | velocity: @jump_force}
    new_assigns = Map.put(screen.assigns, :bird, new_bird)
    {:render, %{screen | assigns: new_assigns}}
  end

  def handle_button("BTN_1", 0, %{assigns: %{game_state: :game_over}} = screen) do
    new_state = start_game(screen.assigns)
    screen = %{screen | assigns: Map.merge(screen.assigns, new_state)}
    schedule_game_tick()
    {:render, screen}
  end

  def handle_button("BTN_2", 0, screen) do
    {:render, navigate(screen, :back)}
  end

  def handle_button(_, _, screen) do
    {:norender, screen}
  end

  def handle_refresh(%{assigns: %{game_state: :playing}} = screen) do
    new_assigns = update_game(screen.assigns)
    screen = %{screen | assigns: new_assigns}
    
    # Continue game loop if still playing
    if new_assigns.game_state == :playing do
      schedule_game_tick()
      {:render, screen}
    else
      # Game over - stop the loop
      {:render, screen}
    end
  end

  def handle_refresh(screen) do
    {:norender, screen}
  end

  defp schedule_game_tick do
    Process.send_after(NameBadge.Renderer, :render, 3000) # ~0.3 FPS
  end

  # Game loop - this would typically be called by a timer or game loop
  def update_game(%{game_state: :playing} = assigns) do
    # Update bird physics
    new_velocity = assigns.bird.velocity + @gravity
    new_y = assigns.bird.y + new_velocity
    new_bird = %{assigns.bird | y: new_y, velocity: new_velocity}

    # Update pipes
    new_pipes = 
      assigns.pipes
      |> Enum.map(fn pipe -> %{pipe | x: pipe.x - @pipe_speed} end)
      |> Enum.reject(fn pipe -> pipe.x < -@pipe_width end)

    # Add new pipes
    new_pipes = 
      if assigns.pipe_timer <= 0 do
        pipe_y = :rand.uniform(150) + 50
        [%{x: 400, y: pipe_y} | new_pipes]
      else
        new_pipes
      end

    # Update timers - slower pipe generation for slow refresh
    new_pipe_timer = if assigns.pipe_timer <= 0, do: 3, else: assigns.pipe_timer - 1
    new_game_timer = assigns.game_timer + 1

    # Check collisions
    game_state = check_collisions(new_bird, new_pipes)

    # Update score
    new_score = if game_state == :playing, do: assigns.score + 1, else: assigns.score

    # Update high score
    new_high_score = max(assigns.high_score, new_score)

    %{
      bird: new_bird,
      pipes: new_pipes,
      score: new_score,
      high_score: new_high_score,
      pipe_timer: new_pipe_timer,
      game_timer: new_game_timer,
      game_state: game_state
    }
  end

  def update_game(assigns), do: assigns

  defp start_game(assigns) do
    %{
      game_state: :playing,
      bird: %{x: 80, y: 150, velocity: 0},
      pipes: [],
      score: 0,
      pipe_timer: 0,
      game_timer: 0
    }
  end

  defp check_collisions(bird, pipes) do
    # Check ground collision (screen height is 300pt)
    if bird.y >= 300 - @bird_size do
      :game_over
    else
      # Check pipe collisions
      bird_left = bird.x
      bird_right = bird.x + @bird_size
      bird_top = bird.y
      bird_bottom = bird.y + @bird_size

      collision = Enum.any?(pipes, fn pipe ->
        pipe_left = pipe.x
        pipe_right = pipe.x + @pipe_width
        
        # Check if bird is horizontally aligned with pipe
        horizontal_overlap = bird_right > pipe_left and bird_left < pipe_right
        
        if horizontal_overlap do
          # Check if bird hits top or bottom pipe
          bird_top < pipe.y or bird_bottom > pipe.y + @pipe_gap
        else
          false
        end
      end)

      if collision, do: :game_over, else: :playing
    end
  end
end