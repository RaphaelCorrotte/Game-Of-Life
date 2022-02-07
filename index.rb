# frozen_string_literal: true

require "gosu"

class Cell
  WIDTH = 20
  HEIGHT = 20
  attr_reader :x_position, :y_position, :neighbours_cells
  attr_accessor :status, :next_status

  def initialize(x_position, y_position)
    @x_position = x_position
    @y_position = y_position
    @neighbours_cells = [[@x_position - 1, @y_position - 1], [@x_position, @y_position - 1], [@x_position + 1, @y_position - 1], [@x_position + 1, @y_position],
                         [@x_position - 1, @y_position], [@x_position - 1, @y_position + 1], [@x_position, @y_position + 1], [@x_position + 1, @y_position + 1]]
    @status = :dead
    @next_status = nil
  end
end

class LifeGame < Gosu::Window
  WIDTH = HEIGHT = 600
  GAME_WIDTH = GAME_HEIGHT = 500

  X_CELLS_COUNT = GAME_WIDTH / Cell::WIDTH
  Y_CELLS_COUNT = GAME_HEIGHT / Cell::WIDTH
  BUTTONS = Hash[
    :START => [[10, 20], [85, 60]],
    :PAUSE => [[10, 75], [85, 115]],
    :NEXT => [[10, 130], [85, 170]],
    :CLEAR => [[10, 185], [85, 225]],
    :LEAVE => [[10, 240], [85, 280]],
  ]
  attr_accessor :launched

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Game of Life"
    self.text_input = Gosu::TextInput.new
    @font = Gosu::Font.new(50)
    @cells = Array.new(X_CELLS_COUNT * Y_CELLS_COUNT)
    @buttons = Hash[
      :CLEAR => Hash[
        :button => Gosu::Image.new("images/clear.png", :tileable => true),
        :clicked_button => Gosu::Image.new("images/clicked_clear.png", :tileable => true)
      ],
      :LEAVE => Hash[
        :button => Gosu::Image.new("images/leave.png", :tileable => true),
        :clicked_button => Gosu::Image.new("images/clicked_leave.png", :tileable => true)
      ],
      :START => Hash[
        :button => Gosu::Image.new("images/start.png", :tileable => true),
        :clicked_button => Gosu::Image.new("images/clicked_start.png", :tileable => true)
      ],
      :PAUSE => Hash[
        :button => Gosu::Image.new("images/pause.png", :tileable => true),
        :clicked_button => Gosu::Image.new("images/clicked_pause.png", :tileable => true)
      ],
      :NEXT => Hash[
        :button => Gosu::Image.new("images/next.png", :tileable => true),
        :clicked_button => Gosu::Image.new("images/clicked_next.png", :tileable => true)
      ]
    ]
    cell = 0
    X_CELLS_COUNT.times do |x_cell|
      Y_CELLS_COUNT.times do |y_cell|
        @cells[cell] = Cell.new(x_cell + (WIDTH - GAME_WIDTH) / Cell::WIDTH, y_cell + (HEIGHT - GAME_HEIGHT) / Cell::HEIGHT)
        cell += 1
      end
    end
  end

  def update
    return unless @launched

    updated_cells = []
    @cells.each do |cell|
      neighbours = []
      cell.neighbours_cells.each do |x, y|
        next neighbours << Cell.new(0, 0) if x.negative? || y.negative?

        neighbours << (@cells.find { |c| c.x_position == x && c.y_position == y } || Cell.new(0, 0))
      end
      alive = neighbours.filter { |c| c.status == :alive }.size

      cell.next_status = if cell.status == :alive
                           if [2, 3].include?(alive)
                             :alive
                           else
                             :dead
                           end
                         elsif alive == 3
                           :alive
                         else
                           :dead
                         end
      updated_cells << cell unless cell.status == cell.next_status
    end

    updated_cells.each do |cell|
      cell.status = cell.next_status
      cell.next_status = nil
    end
  end

  def draw
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.argb(0xff_ffffff))
    @cells.filter { |c| c.status == :alive }.each do |cell|
      Gosu.draw_rect(cell.x_position * Cell::WIDTH, cell.y_position * Cell::HEIGHT, Cell::WIDTH, Cell::HEIGHT, Gosu::Color.argb(0xff_000000))
    end

    x_index = WIDTH - GAME_WIDTH
    y_index = HEIGHT - GAME_HEIGHT
    (X_CELLS_COUNT + 1).times do
      Gosu.draw_line(x_index, WIDTH - GAME_WIDTH, Gosu::Color.argb(0xff_000000), x_index, HEIGHT, Gosu::Color.argb(0xff_000000))
      Gosu.draw_line(HEIGHT - GAME_HEIGHT, y_index, Gosu::Color.argb(0xff_000000), WIDTH, y_index, Gosu::Color.argb(0xff_000000))
      y_index += Cell::WIDTH
      x_index += Cell::HEIGHT
    end

    Gosu.draw_rect(0, 0, WIDTH - GAME_WIDTH - 1, GAME_WIDTH, Gosu::Color.argb(0xff_ffffff))
    Gosu.draw_rect(0, 0, HEIGHT - GAME_HEIGHT - 1, HEIGHT, Gosu::Color.argb(0xff_ffffff))
    @font.draw_text("Game of Life", HEIGHT - GAME_HEIGHT, 10, 2, 1.9, 1.9, Gosu::Color::BLACK)
    Gosu.draw_line(HEIGHT - GAME_HEIGHT, 0, Gosu::Color.argb(0xff_000000), HEIGHT - GAME_HEIGHT, HEIGHT, Gosu::Color.argb(0xff_000000))
    button = mouse_over_button(mouse_x, mouse_y)
    @buttons.each do |key, buttons|
      buttons[:button].draw(BUTTONS[key][0][0], BUTTONS[key][0][1], 0)
      buttons[:clicked_button].draw(BUTTONS[key][0][0], BUTTONS[key][0][1], 0) if button == key && !%i[START PAUSE].include?(key)
    end

    if @launched
      @buttons[:START][:clicked_button].draw(BUTTONS[:START][0][0], BUTTONS[:START][0][1], 0)
    else
      @buttons[:PAUSE][:clicked_button].draw(BUTTONS[:PAUSE][0][0], BUTTONS[:PAUSE][0][1], 0)
    end
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      cell = clicked_cell(mouse_x, mouse_y)
      cell.status = (cell.status == :alive ? :dead : :alive) if cell
      button = mouse_over_button(mouse_x, mouse_y)
      close! if button == :LEAVE
      @cells.each { |c| c.status = :dead } if button == :CLEAR
      if @launched
        @launched = false if button == :PAUSE
      else
        @launched = true if button == :START
      end
      if button == :NEXT
        proc do
          next if @launched

          @launched = true
          update
          @launched = false
        end.call
      end
    when Gosu::MsRight
      @launched = @launched ? false : true
    when Gosu::KB_TAB
      @cells.each { |c| c.status = :dead }
    when Gosu::KB_ESCAPE
      close!
    end
  end

  def clicked_cell(mouse_x, mouse_y)
    @cells.find do |cell|
      mouse_x.between?(cell.x_position * Cell::WIDTH, cell.x_position * Cell::WIDTH + Cell::WIDTH) &&
        mouse_y.between?(cell.y_position * Cell::WIDTH, cell.y_position * Cell::HEIGHT + Cell::HEIGHT)
    end
  end

  def mouse_over_button(mouse_x, mouse_y)
    BUTTONS.each do |key, position|
      return key if mouse_x.between?(position[0][0], position[1][0]) && mouse_y.between?(position[0][1], position[1][1])
    end
  end
end

LifeGame.new.show
