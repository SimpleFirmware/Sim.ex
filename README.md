iex(2)> {:ok, pid} = BigMarsh.V1Simulator.start_link([])
{:ok, #PID<0.203.0>}
iex(3)> BigMarsh.V1Simulator.add_drone_type("test", 30.0, 10.0, 2.0, 5.0)
:ok
iex(4)> BigMarsh.V1Simulator.add_drone(1, "test", -87.64218256846847, 41.68516340084044, 100.0, -87.61144234984356, 41.685561808243065, 30.0)
:ok
iex(5)> BigMarsh.V1Simulator.internal_state()
%{
  drone_types: %{
    "test" => %{
      maximum_speed: 30.0,
      maximum_load_in_lbs: 10.0,
      average_percentage_drop_per_mi: 2.0,
      average_percentage_gain_per_min: 5.0
    }
  },
  drones: %{
    1 => %{
      drone_type_name: "test",
      drone_current_lon: -87.64218256846847,
      drone_current_lat: 41.68516340084044,
      drone_current_percentage: 100.0,
      target_lon: -87.61144234984356,
      target_lat: 41.685561808243065,
      target_interval_secs: 30.0,
      current_tick: 0,
      points: [
        {-87.63734922604256, 41.685226586222846, 96.82},
        {-87.63251587413875, 41.6852895691031, 94.13999999999999},
        {-87.62768251278743, 41.68535234948036, 91.95999999999998},
        {-87.62284914201899, 41.6854149273538, 90.27999999999997},
        {-87.61801576186382, 41.68547730272256, 89.09999999999997},
        {-87.61318237235228, 41.685539475585806, 88.41999999999996},
        {-87.61144234984356, 41.685561808243065, 88.23999999999995}
      ]
    }
  }
}
iex(6)> BigMarsh.V1Simulator.get_drone_tick(1)
{-87.63734922604256, 41.685226586222846, 96.82}
iex(7)> BigMarsh.V1Simulator.get_drone_tick(1)
{-87.63251587413875, 41.6852895691031, 94.13999999999999}
iex(8)> BigMarsh.V1Simulator.set_new_target_destination(1, -87.64218256846847, 41.68516340084044 , 30.0)
:ok
iex(9)> BigMarsh.V1Simulator.get_drone_tick(1)
{-87.63734922604256, 41.685226586222846, 93.13999999999999}
iex(10)> BigMarsh.V1Simulator.get_drone_tick(1)
{-87.64218256846847, 41.68516340084044, 92.63999999999999}
iex(11)> BigMarsh.V1Simulator.get_drone_tick(1)
:out_of_ticks
