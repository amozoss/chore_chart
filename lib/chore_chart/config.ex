defmodule ChoreChart.Config do
  @moduledoc """
  Configuration for the chore chart application.
  """

  def kids do
    %{
      "jack" => %{
        password: "321",
        color: "#d4af37",
        picture: "/img/kids/jack.jpg",
        super: false
      },
      "jill" => %{
        password: "132",
        color: "turquoise",
        picture: "/img/kids/jill.jpg",
        super: false
      }
    }
  end

  def everyday do
    %{
      "jack" => ["bedroom", "piano"],
      "jill" => ["bedroom", "piano"]
    }
  end

  def matrix do
    %{
      "jack" => [
        [],
        ["homework", "pantry", "weeds"],
        ["homework", "dishes"],
        ["homework", "clothes"],
        ["homework", "garbage", "dishes"],
        ["homework"],
        ["weeds"]
      ],
      "jill" => [
        [],
        ["homework", "clothes", "dishes"],
        ["homework", "sweep"],
        ["homework", "sweep"],
        ["homework", "garbage"],
        ["homework"],
        []
      ]
    }
  end

  def chore_icons do
    %{
      "bathroom" => "🚻",
      "bedroom" => "🛏️",
      "clothes" => "👕",
      "dishes" => "🍽️",
      "garbage" => "🗑️",
      "homework" => "📝",
      "lawn" => "🏡",
      "piano" => "🎹",
      "sweep" => "🧹",
      "weeds" => "🌱",
      "pantry" => "🥫"
    }
  end

  def get_chores_for_day(username) do
    # Get everyday chores
    everyday_chores = everyday()[username] || []

    # Get matrix chores for today
    # Date.day_of_week returns 1-7 where 1 is Monday
    # We need to convert to 0-6 where 0 is Sunday
    day_of_week = Date.day_of_week(Date.utc_today())
    # Convert Monday=1 to Sunday=0
    matrix_index = rem(day_of_week + 5, 7)
    matrix_chores = get_in(matrix(), [username, Access.at(matrix_index)]) || []

    everyday_chores ++ matrix_chores
  end

  def get_kid_color(username) do
    case kids()[username] do
      %{color: color} -> color
      # Default color
      _ -> "#666666"
    end
  end

  def get_kid_picture(username) do
    case kids()[username] do
      %{picture: picture} -> picture
      # Default picture
      _ -> "/images/default-avatar.png"
    end
  end
end
