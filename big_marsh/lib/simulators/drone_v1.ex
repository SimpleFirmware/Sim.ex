

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


  def handle_call(:state, _from, state) do
    {:reply, state, state}
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

  def handle_cast({:new_location_target, drone_id, target_lon, target_lat , target_interval_secs}, state) do
    drones = Map.get(state, :drones)
    drone =
      Map.get(drones, drone_id) |>
      Map.put(:target_lon, target_lon) |>
      Map.put(:target_lat, target_lat)
    drone_type_name = Map.get(drone, :drone_type_name)
    mph =
      Map.get(state, :drone_types) |>
      Map.get(drone_type_name) |>
      Map.get(:maximum_speed)
    drone_current_lon = Map.get(drone, :drone_current_lon)
    drone_current_lat = Map.get(drone, :drone_current_lat)
    points = calulate_points(
      [],
      drone_type_name,
      drone_current_lon,
      drone_current_lat,
      target_lon,
      target_lat,
      target_interval_secs,
      mph
    )
    drone = Map.put(drone, :points, points)
    drones = Map.put(drones, drone_id, drone)

    state = Map.put(state, :drones, drones)
    {:noreply, state}
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
    target_interval_secs}, state) do
      mph =
        Map.get(state, :drone_types) |>
        Map.get(drone_type_name) |>
        Map.get(:maximum_speed)
      points = calulate_points(
        [],
        drone_type_name,
        drone_current_lon,
        drone_current_lat,
        target_lon,
        target_lat,
        target_interval_secs,
        mph
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
    current_tick = Map.get(drone, :current_tick) + 1
    drone = Map.put(drone, :current_tick, current_tick)

    # Get our new tick related point
    points = Map.get(drone, :points)
    out_of_ticks = current_tick > Enum.count(points)
    case out_of_ticks do
      true ->
        {:reply,:out_of_ticks, state}
      false ->
        {lon, lat} = Enum.at(points, current_tick - 1)
        drone =
          Map.put(drone, :drone_current_lon, lon) |>
          Map.put(:drone_current_lat, lat)
        drones = drones |> Map.put(drone_id, drone)
        state = Map.put(state, :drones, drones)
        {:reply,{lon, lat}, state}
    end
  end

  def handle_cast({:remove_drone, drone_id}, state) do
    state = Map.drop(state, [drone_id])
    {:noreply, state}
  end

  # Little test...
  # {:ok, pid} = BigMarsh.V1Simulator.start_link([])
  # GenServer.cast(pid, {:add_drone_type, "test", 30.0, 10.0, 2.0, 5.0})
  # GenServer.cast(pid, {:add_drone, 1, "test", -87.64218256846847, 41.68516340084044, 10.0, -87.61144234984356, 41.685561808243065, 30.0})
  #{-87.61144234984356, 41.685561808243065}, -> 115th cottage grove
  #{-87.61318237235228, 41.685539475585806}, -> 115th king dr
  #{-87.61801576186382, 41.68547730272256}, -> 115th indiana
  #{-87.62284914201899, 41.6854149273538}, -> 115th state
  #{-87.62768251278743, 41.68535234948036}, -> 115th wentworth
  #{-87.63251587413875, 41.6852895691031}, -> 115th stewart
  #{-87.63734922604256, 41.685226586222846} -> 115th wallace

  defp calulate_points(
    points,
    drone_type_name,
    drone_current_lon,
    drone_current_lat,
    target_lon,
    target_lat,
    target_interval_secs,
    mph
  ) do
      distance_in_miles = distance_between_points_in_miles(drone_current_lon, drone_current_lat, target_lon, target_lat)
      seconds_to_go_distance = distance_in_miles_to_seconds(distance_in_miles, mph)
      miles_per_second = Decimal.div(
        Decimal.from_float(distance_in_miles),
        seconds_to_go_distance)
      miles_per_interval = Decimal.mult(Decimal.from_float(target_interval_secs), miles_per_second)
      percentage_traveled_per_interval = Decimal.mult(Decimal.div(miles_per_interval, Decimal.from_float(distance_in_miles)),100)
      #line interpolation

      {new_lon, new_lat} =
        calculate_new_intermediate_point(
          drone_current_lon,
          drone_current_lat,
          target_lon,target_lat,
          Decimal.to_float(percentage_traveled_per_interval)/100
        )
      new_lat_float = new_lat
      new_lon_float = new_lon
      # does the new lon/lat reside on our line?
      # let C = new lon/lat
      # if distance(drone_current_location, C) + distance(c, target_location) == distance(drone_current_location, target_location)
      # it is said the new point is on the line, which makes it a valid point
      curr_to_new = distance_between_points_in_miles(drone_current_lon, drone_current_lat, new_lon_float, new_lat_float)
      new_to_target = distance_between_points_in_miles(target_lon, target_lat, new_lon_float, new_lat_float)

      is_valid_point =
        Decimal.to_float(
          Decimal.round(
            Decimal.add(
              Decimal.from_float(curr_to_new),
              Decimal.from_float(new_to_target)),2)) == distance_in_miles
      case is_valid_point do
        true ->
          calulate_points(
            [{new_lon_float, new_lat_float} | points],
            drone_type_name,new_lon_float,
            new_lat_float,
            target_lon,
            target_lat,
            target_interval_secs ,
            mph
          )
        false ->
          # Did the target destination get added
          # as a point? If not we need to append it
          # since obviously it will always be the last.
          has_target_dest = Enum.any?(
            points,
            fn point ->
              elem(point,0) == target_lon and
              elem(point, 1) == target_lat end
          )
          case has_target_dest do
            true -> points
            false -> [{target_lon, target_lat} | points]
          end
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

  # Find new points along the line between where the drone is
  # currently vs end destination.
  defp calculate_new_intermediate_point(lon1, lat1, lon2, lat2,  percentage) do
    lon1 = degreeToRadians(lon1)
    lat1 = degreeToRadians(lat1)
    lon2 = degreeToRadians(lon2)
    lat2 = degreeToRadians(lat2)

    delta_lat = lat2 - lat1;
    delta_lng =  lon2 - lon1;

    calc_a =
      :math.sin(delta_lat / 2) * :math.sin(delta_lat / 2) +
      :math.cos(lat1) *  :math.cos(lat2) * :math.sin(delta_lng / 2) * :math.sin(delta_lng / 2);
    calc_b = 2 * :math.atan2(:math.sqrt(calc_a), :math.sqrt(1 - calc_a));

    a = :math.sin((1 - percentage) * calc_b) / :math.sin(calc_b);
    b = :math.sin(percentage * calc_b) / :math.sin(calc_b);

    x = a * :math.cos(lat1) * :math.cos(lon1) + b * :math.cos(lat2) * :math.cos(lon2);
    y = a * :math.cos(lat1) * :math.sin(lon1) + b * :math.cos(lat2) * :math.sin(lon2);
    z = a * :math.sin(lat1) + b * :math.sin(lat2);

    lat3 = :math.atan2(z, :math.sqrt(x * x + y * y));
    lng3 = :math.atan2(y, x);
    {radiansToDegrees(lng3), radiansToDegrees(lat3)}
  end

  defp degreeToRadians (degree) do
    pi = 3.14159265359
    degree * (pi/180)
  end

  defp radiansToDegrees(radians) do
    pi = 3.14159265359
    radians * (180/pi)
  end
end
