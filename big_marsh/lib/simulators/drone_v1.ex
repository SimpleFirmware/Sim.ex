

defmodule BigMarsh.V1Simulator do
  @moduledoc """
    This is the v1 drone simulator a simulator that
    given a few data points can predict the locations
    of the drone on an interval, the v1 simulator focuses
    on a start and end destination. Meaning it will not
    account for adding stops. If you want to add a stop
    mid simulation, then you need to regenerate the simulation
    entirely.

    This v1 simulator is for linear simulations only.

    Ideally later in a different simulation version we will allow
    more efficient "add stop" calculations and other features
    like path diverge based on object avoidance.

  """
  alias ExUnit.Case
  use GenServer

  @server_name :drone_simulator
  def start_link(_) do
    # Intended to be a single process in any consumption so this
    # name should be fine
    GenServer.start_link(__MODULE__, nil, name: @server_name)
  end

  def init(_) do
    {
      :ok,
      %{
        drone_types: %{},
        drones: %{}
      }
    }
  end

  def handle_cast({
    :add_drone_type,
    drone_type_name,
    maximum_speed,
    maximum_load_in_lbs,
    average_percentage_drop_per_mi,
    average_percentage_gain_per_min}, state) do
      type_map =
        Map.get(state, :drone_types) |>
        Map.put(
          drone_type_name,
          %{
            maximum_speed: maximum_speed,
            maximum_load_in_lbs: maximum_load_in_lbs,
            average_percentage_drop_per_mi: average_percentage_drop_per_mi,
            average_percentage_gain_per_min: average_percentage_gain_per_min
          }
        )
      state = Map.put(state, :drone_types, type_map)
      {:noreply, state}
  end

  # Current interval is for the calculation
  # of how much distance should be covered per
  # call of :tick_drone. It assumes that you will
  # call :tick_drone in your consuming application
  # on the same interval supplied here.
  #
  # To keep things simple, current interval can not be
  # changed! You must set the simulation up again from
  # the beginning.
  def handle_cast({
    :add_drone,
    drone_id,
    drone_type_name,
    drone_current_lon,
    drone_current_lat,
    drone_current_percentage,
    target_lon,
    target_lat,
    target_interval}, state) do
      points = calulate_points(
        drone_type_name,
        drone_current_lon,
        drone_current_lat,
        drone_current_percentage,
        target_lon,
        target_lat,
        target_interval_secs,
        state
      )
      drones =
        Map.get(state, :drones) |>
        Map.put(
          drone_id,
          %{
            drone_type_name: drone_type_name,
            drone_current_lon: drone_current_lon,
            drone_current_lat: drone_current_lat,
            target_lon: target_lon,
            target_lat: target_lat,
            target_interval_secs: target_interval_secs,
            current_tick: 0,
            points: points
          }
        )
      state = Map.put(state, :drones, drones)
      {:noreply, state}
  end

  def handle_call({:tick_drone, drone_id}, _from ,state) do
    drones = Map.get(state, :drones)
    drone = drones |> Map.get(drone_id)

    # Update our current tick
    current_tick = Map.get(drone, :curent_tick) + 1
    drone = Map.put(drone, :current_tick, current_tick)

    # Get our new tick related point
    points = Map.get(drone, points)
    {lon, lat} = Enum.at(points, current_tick - 1)

    # persist state
    drones = drones |> Map.put(drone_id, drone)
    state = Map.put(state, :drones, drones)
    {:reply,{lon, lat}, state}
  end

  def handle_cast({:remove_drone, drone_id}, state) do
    state = Map.drop(state, [drone_id])
    {:noreply, state}
  end

  defp calulate_points(
    points,
    drone_type_name,
    drone_current_lon,
    drone_current_lat,
    target_lon,
    target_lat,
    target_interval_secs,
    state
  ) do
      mph =
        Map.get(state, :drone_types) |>
        Map.get(drone_type_name) |>
        Map.get(:maximum_speed)
      distance_in_miles = distance_between_points_in_miles(drone_current_lon, drone_current_lat, target_lon, target_lat)
      seconds_to_go_distance = distance_in_miles_to_seconds(distance, mph)
      miles_per_second = Decimal.div(
        Decimal.from_float(distance_in_miles),
        seconds_to_go_distance)
      miles_per_interval = Decimal.mult(Decimal.from_float(target_interval_secs), miles_per_second)
      percentage_traveled_per_interval = Decimal.mult(Decimal.div(miles_per_interval, Decimal.from_float(distance_in_miles)),100)
      #line interpolation

      lon_diff = Decimal.sub(Decimal.from_float(drone_current_lon), Decimal.from_float(target_lon))
      lat_diff = Decimal.sub(Decimal.from_float(drone_current_lat), Decimal.from_float(target_lat))

      new_lat = Decimal.add(Decimal.from_float(drone_current_lat), Decimal.mult(lat_diff, percentage_traveled_per_interval))
      new_lon = Decimal.add(Decimal.from_float(drone_current_lon), Decimal.mult(lon_diff, percentage_traveled_per_interval))

      new_lat_float = new_lat |> Decimal.to_float()
      new_lon_float = new_lon |> Decimal.to_float()
      # does the new lon/lat reside on our line?
      # let C = new lon/lat
      # if distance(drone_current_location, C) + distance(c, target_location) == distance(drone_current_location, target_location)
      # it is said the new point is on the line, which makes it a valid point
      curr_to_new = distance_between_points_in_miles(drone_current_lon, drone_current_lat, new_lon_float, new_lat_float)
      new_to_target = distance_between_points_in_miles(target_lon, target_lat, new_lon_float, new_lat_float)
      is_valid_point = curr_to_new + new_to_target == distance_in_miles
      case is_valid_point do
        true ->
          calulate_points(
            [{new_lon_float, new_lat_float} | points],
            drone_type_name,new_lon_float,
            new_lat_float,
            target_lon,
            target_lat,
            target_interval_secs ,
            state
          )
        false -> points
      end
  end

  defp distance_in_miles_to_seconds(distance, mph) do
    Decimal.div(
      Decimal.from_float(distance),
      Decimal.from_float(mph)
    )
    |>
    Decimal.mult(60)
    |>
    Decimal.mult(60)
    |>
    Decimal.round(2)
  end

  defp distance_between_points_in_miles(starting_lon, starting_lat, ending_lon, ending_lat) do
    # meters to miles
    # confirmed this method actually works by cross comparing
    # to google maps, keep in mind this is straight line distance
    # so the distances by car calculated by google maps or any other route
    # based distance will usually be greater. This is actually one of the
    # selling points of air delivery, the idea that the fastest route
    # between any two points is a straight line resulting in shorter
    # distance required for delivery.
    Decimal.from_float(Distance.GreatCircle.distance({starting_lon, starting_lat}, {ending_lon, ending_lat}) * 0.000621371) |>
    Decimal.round(2)|>
    Decimal.to_float()
  end
end
