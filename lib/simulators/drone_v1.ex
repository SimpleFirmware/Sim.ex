

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
  use GenServer
  require Logger

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

  @doc """
    Adds a Drone type that is used
    for metadata of the following added
    drones.

    Returns `""`.

  ## Examples

      iex> BigMarsh.V1Simulator.add_drone_type("test", 30.0, 10.0, 2.0, 5.0)
      :ok

  """
  def add_drone_type(
    drone_type_name,
    maximum_speed,
    maximum_load_in_lbs,
    average_percentage_drop_per_mi,
    average_percentage_gain_per_min) do
      GenServer.call(
        @server_name,
        {
          :add_drone_type,
          drone_type_name,
          maximum_speed,
          maximum_load_in_lbs,
          average_percentage_drop_per_mi,
          average_percentage_gain_per_min
        })
  end

  @doc """
    Adds a Drone and calculates
    its next points based on
    the provided data. Later
    to be gathered by get_drone_tick()

    Returns `""`.

  ## Examples

      iex> BigMarsh.V1Simulator.add_drone(1, "test", -87.64218256846847, 41.68516340084044, 100.0, -87.61144234984356, 41.685561808243065, 30.0)
      :ok

  """
  def add_drone(
    drone_id,
    drone_type_name,
    drone_current_lon,
    drone_current_lat,
    drone_current_percentage,
    target_lon,
    target_lat,
    target_interval_secs) do
      GenServer.call(
        @server_name,
        {
          :add_drone,
          drone_id,
          drone_type_name,
          drone_current_lon,
          drone_current_lat,
          drone_current_percentage,
          target_lon,
          target_lat,
          target_interval_secs
        })
  end
  @doc """
    changes the target destination of
    a drone id and recalculates the points
    that are to be gathered by calling get_drone_tick()

    Returns `""`.

  ## Examples

    iex(8)> BigMarsh.V1Simulator.set_new_target_destination(1, -87.64218256846847, 41.68516340084044 , 30.0)
    :ok
  """
  def set_new_target_destination(
    drone_id,
    target_lon,
    target_lat ,
    target_interval_secs) do
      GenServer.call(
        @server_name,
        {
          :new_location_target,
          drone_id,
          target_lon,
          target_lat ,
          target_interval_secs
        }
      )
  end

  @doc """
      Gives you the next {lon, lat, percentage} of a drone
      based on the defined interval.

    Returns {lon, lat, percentage} when ticks are present and
    :out_of_ticks when you are at the target destination

  ## Examples

    iex(8)> BigMarsh.V1Simulator.get_drone_tick(1)

  """
  def get_drone_tick(drone_id) do
    GenServer.call(@server_name, {:tick_drone, drone_id})
  end

  def internal_state() do
    GenServer.call(@server_name, :state)
  end
  # ---- API END----

  def handle_call(:state, _from, state) do
    {:reply, state, state}
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
        {lon, lat, percentage} = Enum.at(points, current_tick - 1)
        drone =
          Map.put(drone, :drone_current_lon, lon) |>
          Map.put(:drone_current_lat, lat) |>
          Map.put(:drone_current_percentage, percentage)
        drones = drones |> Map.put(drone_id, drone)
        state = Map.put(state, :drones, drones)
        {:reply,{lon, lat, percentage}, state}
    end
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
  def handle_call({
    :add_drone,
    drone_id,
    drone_type_name,
    drone_current_lon,
    drone_current_lat,
    drone_current_percentage,
    target_lon,
    target_lat,
    target_interval_secs}, _from, state) do
      mph =
        Map.get(state, :drone_types) |>
        Map.get(drone_type_name) |>
        Map.get(:maximum_speed)
      pdpm =
        Map.get(state, :drone_types) |>
        Map.get(drone_type_name) |>
        Map.get(:average_percentage_drop_per_mi)
      per_interval_percentage =
        get_percentage_traveled_per_interval(
          drone_current_lon,
          drone_current_lat,
          target_lon,
          target_lat,
          target_interval_secs,
          mph
        )
      points = Enum.reverse(calulate_points(
        [],
        drone_type_name,
        drone_current_lon,
        drone_current_lat,
        target_lon,
        target_lat,
        target_interval_secs,
        mph,
        drone_current_percentage,
        pdpm,
        per_interval_percentage,
        1.0
      ))

      Logger.info("num of points: #{Enum.count(points)}")
      IO.inspect(points)
      drones =
        Map.get(state, :drones) |>
        Map.put(
          drone_id,
          %{
            drone_type_name: drone_type_name,
            drone_current_lon: drone_current_lon,
            drone_current_lat: drone_current_lat,
            drone_current_percentage: drone_current_percentage,
            target_lon: target_lon,
            target_lat: target_lat,
            target_interval_secs: target_interval_secs,
            current_tick: 0,
            points: points
          }
        )
      state = Map.put(state, :drones, drones)
      {:reply, "", state}
  end
    # Starting from the example listed above calulate_points
  #GenServer.call(pid, {:new_location_target, 1, -87.64218256846847, 41.68516340084044 , 30.0})
  #{-87.64218256846847, 41.68516340084044}, -> 115th halsted
  #{-87.6404425662889, 41.68518617090629},  -> Between emerald and parnell
  #{-87.63560922044744, 41.68524928338801}, -> Between normal and parnell closer to parnell
  #{-87.63077586513903, 41.68531219336729}, -> Between princeton and harvard
  #{-87.62594250039405, 41.68537490084328}, -> Between wentworth and state, closer to state
  #{-87.62110912624289, 41.68543740581512}, -> Between michigan and state, closer to michigan
  #{-87.61627574271593, 41.685499708281995} -> Between 115th prairie and forest
  #
  # Read these points in reverse order(bottom to top) as they are
  # stored in memory reversed and ticked(requested) bottom to top
  def handle_call({:new_location_target, drone_id, target_lon, target_lat , target_interval_secs},_from, state) do
    drones = Map.get(state, :drones)
    drone =
      Map.get(drones, drone_id) |>
      Map.put(:target_lon, target_lon) |>
      Map.put(:target_lat, target_lat) |>
      Map.put(:current_tick, 0)
    drone_current_lon = Map.get(drone, :drone_current_lon)
    drone_current_lat = Map.get(drone, :drone_current_lat)
    is_same_target_location =
      drone_current_lat == target_lat and
      drone_current_lon == target_lon
    state = case is_same_target_location do
      true -> state
      false ->
        drone_type_name = Map.get(drone, :drone_type_name)
        mph =
          Map.get(state, :drone_types) |>
          Map.get(drone_type_name) |>
          Map.get(:maximum_speed)
        pdpm =
          Map.get(state, :drone_types) |>
          Map.get(drone_type_name) |>
          Map.get(:average_percentage_drop_per_mi)

        drone_current_percentage = Map.get(drone, :drone_current_percentage)
        per_interval_percentage =
          get_percentage_traveled_per_interval(
            drone_current_lon,
            drone_current_lat,
            target_lon,
            target_lat,
            target_interval_secs,
            mph
          )
        points = Enum.reverse(calulate_points(
          [],
          drone_type_name,
          drone_current_lon,
          drone_current_lat,
          target_lon,
          target_lat,
          target_interval_secs,
          mph,
          drone_current_percentage,
          pdpm,
          per_interval_percentage,
          1.0
        ))
        Logger.info("num of points simulated: #{Enum.count(points)}")
        IO.inspect(points)
        drone = Map.put(drone, :points, points)
        drones = Map.put(drones, drone_id, drone)
        Map.put(state, :drones, drones)
    end
    {:reply, "", state}
  end

  def handle_call({
    :add_drone_type,
    drone_type_name,
    maximum_speed,
    maximum_load_in_lbs,
    average_percentage_drop_per_mi,
    average_percentage_gain_per_min},_from, state) do
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
      {:reply,"", state}
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
  #
  # Read these points in reverse order(bottom to top) as they are
  # stored in memory reversed and ticked(requested) bottom to top

  defp calulate_points(
    points,
    drone_type_name,
    drone_current_lon,
    drone_current_lat,
    target_lon,
    target_lat,
    target_interval_secs,
    mph,
    drone_current_percentage,
    pdpm,# average percentage drop per_mile
    percentage_traveled_per_interval,
    current_interval_index
  ) do
      distance_in_miles = distance_between_points_in_miles(drone_current_lon, drone_current_lat, target_lon, target_lat)
      # if we have a distance of 10 miles
      # and we go 10% per interval this means
      # that our total distance in miles
      # traveled at this current tick will be
      # distance * percentage per tick * current interval index.
      #
      # EX: on the 6th interval tick
      # we should have gone 60% or 6 miles of the 10.
      total_distance_in_miles_at_curr_tick =
        distance_in_miles *
        Decimal.to_float(
          Decimal.mult(
            percentage_traveled_per_interval,
            Decimal.from_float(current_interval_index)
          )
        )/100

      #line interpolation
      {new_lon, new_lat} =
        calculate_new_intermediate_point(
          drone_current_lon,
          drone_current_lat,
          target_lon,target_lat,
          Decimal.to_float(
            # if this is the Nth interval tick
            # we should shift N points over on the
            # line from the start
            Decimal.mult(
              percentage_traveled_per_interval,
              Decimal.from_float(current_interval_index)))/100 # wants decimal representation
        )
      new_lat_float = new_lat
      new_lon_float = new_lon
      # does the new lon/lat reside on our line?
      # let C = new lon/lat
      # if distance(drone_current_location, C) + distance(C, target_location) == distance(drone_current_location, target_location)
      # it is said the new point is on the line, which makes it a valid point
      curr_to_new = distance_between_points_in_miles(drone_current_lon, drone_current_lat, new_lon_float, new_lat_float)
      new_to_target = distance_between_points_in_miles(target_lon, target_lat, new_lon_float, new_lat_float)
      battery_percentage_at_point = drone_current_percentage - (total_distance_in_miles_at_curr_tick * pdpm)

      # shift decimal point 5 over
      # get rid of remaining behind decimal
      # and shift point back over 5 to original location
      curr_total_distance =
        Decimal.to_float(
          Decimal.add(
            Decimal.from_float(curr_to_new),
            Decimal.from_float(new_to_target)))

      # We do this comparison with 5 decimal points
      # because 0.00001 miles is 0.0528 feet. So
      # precise enough for us
      curr_total_distance_trunc = trunc_without_rounding(curr_total_distance, 5)
      total_distance_trunc = trunc_without_rounding(distance_in_miles, 5)
      is_valid_point = curr_total_distance_trunc == total_distance_trunc
      point_is_target_dest = new_lat_float == target_lat and new_lon_float == target_lon

      cond do
        # no need to calculate any further if we know we are
        # at the target dest
        is_valid_point and point_is_target_dest -> [{target_lon, target_lat, battery_percentage_at_point} | points]
        is_valid_point ->
          calulate_points(
            [{new_lon_float, new_lat_float, battery_percentage_at_point} | points],
            drone_type_name,
            drone_current_lon,
            drone_current_lat,
            target_lon,
            target_lat,
            target_interval_secs ,
            mph,
            drone_current_percentage,
            pdpm,
            percentage_traveled_per_interval,
            current_interval_index + 1
          )
        !is_valid_point ->
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
            false -> [{target_lon, target_lat, battery_percentage_at_point} | points]
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
  end

  defp distance_between_points_in_miles(starting_lon, starting_lat, ending_lon, ending_lat) do
    # meters to miles
    Decimal.from_float(Distance.GreatCircle.distance({starting_lon, starting_lat}, {ending_lon, ending_lat}) * 0.000621371) |>
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

  defp trunc_without_rounding(num, n) do
    # For non math folks, if you want to shift
    # the decimal point of a number over by lets say
    # 5 locations, you will multiply the number by
    # 10^5. so it will be 10^n (^ means to the power of)
    shifted_decimal_to_right_n_times =
      Decimal.to_float(Decimal.mult(Decimal.from_float(num), Decimal.from_float(:math.pow(10,n) * 1.0)))
    decimal_to_int = trunc(shifted_decimal_to_right_n_times)
    shifted_decimal_to_left_n_times = Decimal.to_float(Decimal.div(Decimal.from_float(decimal_to_int * 1.0), Decimal.from_float(:math.pow(10,n) * 1.0)))
    shifted_decimal_to_left_n_times
  end

  defp get_percentage_traveled_per_interval(drone_current_lon, drone_current_lat, target_lon, target_lat, target_interval_secs, mph) do
    distance_in_miles = distance_between_points_in_miles(drone_current_lon, drone_current_lat, target_lon, target_lat)
    seconds_to_go_distance = distance_in_miles_to_seconds(distance_in_miles, mph)
    Logger.info("dividing dim:#{distance_in_miles} by stgd:#{Decimal.to_float(seconds_to_go_distance)}")
    miles_per_second = Decimal.div(
      Decimal.from_float(distance_in_miles),
      seconds_to_go_distance)
    miles_per_interval = Decimal.mult(Decimal.from_float(target_interval_secs), miles_per_second)
    Decimal.mult(Decimal.div(miles_per_interval, Decimal.from_float(distance_in_miles)),100)
  end
end
