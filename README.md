<pre>iex(2)&gt; {:ok, pid} = BigMarsh.V1Simulator.start_link([])
{<font color="#2AA1B3">:ok</font>,<font color="#A2734C"> #PID&lt;0.203.0&gt;</font>}
iex(3)&gt; BigMarsh.V1Simulator.add_drone_type(&quot;test&quot;, 30.0, 10.0, 2.0, 5.0)
<font color="#2AA1B3">""</font>
iex(4)&gt; BigMarsh.V1Simulator.add_drone(1, &quot;test&quot;, -87.64218256846847, 41.68516340084044, 100.0, -87.61144234984356, 41.685561808243065, 30.0)
<font color="#2AA1B3">""</font>
iex(5)&gt; BigMarsh.V1Simulator.internal_state()
%{
<font color="#A2734C">  </font><font color="#2AA1B3">drone_types:</font><font color="#A2734C"> </font>%{
<font color="#A2734C">    </font><font color="#26A269">&quot;test&quot;</font> =&gt; %{
<font color="#A2734C">      </font><font color="#2AA1B3">maximum_speed:</font><font color="#A2734C"> 30.0</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">maximum_load_in_lbs:</font><font color="#A2734C"> 10.0</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">average_percentage_drop_per_mi:</font><font color="#A2734C"> 2.0</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">average_percentage_gain_per_min:</font><font color="#A2734C"> 5.0</font>
<font color="#A2734C">    </font>}
<font color="#A2734C">  </font>},
<font color="#A2734C">  </font><font color="#2AA1B3">drones:</font><font color="#A2734C"> </font>%{
<font color="#A2734C">    1</font> =&gt; %{
<font color="#A2734C">      </font><font color="#2AA1B3">drone_type_name:</font><font color="#A2734C"> </font><font color="#26A269">&quot;test&quot;</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">drone_current_lon:</font><font color="#A2734C"> -87.64218256846847</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">drone_current_lat:</font><font color="#A2734C"> 41.68516340084044</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">drone_current_percentage:</font><font color="#A2734C"> 100.0</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">target_lon:</font><font color="#A2734C"> -87.61144234984356</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">target_lat:</font><font color="#A2734C"> 41.685561808243065</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">target_interval_secs:</font><font color="#A2734C"> 30.0</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">current_tick:</font><font color="#A2734C"> 0</font>,
<font color="#A2734C">      </font><font color="#2AA1B3">points:</font><font color="#A2734C"> </font>[
<font color="#A2734C">        </font>{<font color="#A2734C">-87.63734922604256</font>,<font color="#A2734C"> 41.685226586222846</font>,<font color="#A2734C"> 96.82</font>},
<font color="#A2734C">        </font>{<font color="#A2734C">-87.63251587413875</font>,<font color="#A2734C"> 41.6852895691031</font>,<font color="#A2734C"> 94.13999999999999</font>},
<font color="#A2734C">        </font>{<font color="#A2734C">-87.62768251278743</font>,<font color="#A2734C"> 41.68535234948036</font>,<font color="#A2734C"> 91.95999999999998</font>},
<font color="#A2734C">        </font>{<font color="#A2734C">-87.62284914201899</font>,<font color="#A2734C"> 41.6854149273538</font>,<font color="#A2734C"> 90.27999999999997</font>},
<font color="#A2734C">        </font>{<font color="#A2734C">-87.61801576186382</font>,<font color="#A2734C"> 41.68547730272256</font>,<font color="#A2734C"> 89.09999999999997</font>},
<font color="#A2734C">        </font>{<font color="#A2734C">-87.61318237235228</font>,<font color="#A2734C"> 41.685539475585806</font>,<font color="#A2734C"> 88.41999999999996</font>},
<font color="#A2734C">        </font>{<font color="#A2734C">-87.61144234984356</font>,<font color="#A2734C"> 41.685561808243065</font>,<font color="#A2734C"> 88.23999999999995</font>}
<font color="#A2734C">      </font>]
<font color="#A2734C">    </font>}
<font color="#A2734C">  </font>}
}
iex(6)&gt; BigMarsh.V1Simulator.get_drone_tick(1)
{<font color="#A2734C">-87.63734922604256</font>,<font color="#A2734C"> 41.685226586222846</font>,<font color="#A2734C"> 96.82</font>}
iex(7)&gt; BigMarsh.V1Simulator.get_drone_tick(1)
{<font color="#A2734C">-87.63251587413875</font>,<font color="#A2734C"> 41.6852895691031</font>,<font color="#A2734C"> 94.13999999999999</font>}
iex(8)&gt; BigMarsh.V1Simulator.set_new_target_destination(1, -87.64218256846847, 41.68516340084044 , 30.0)
<font color="#2AA1B3">""</font>
iex(9)&gt; BigMarsh.V1Simulator.get_drone_tick(1)
{<font color="#A2734C">-87.63734922604256</font>,<font color="#A2734C"> 41.685226586222846</font>,<font color="#A2734C"> 93.13999999999999</font>}
iex(10)&gt; BigMarsh.V1Simulator.get_drone_tick(1)
{<font color="#A2734C">-87.64218256846847</font>,<font color="#A2734C"> 41.68516340084044</font>,<font color="#A2734C"> 92.63999999999999</font>}
iex(11)&gt; BigMarsh.V1Simulator.get_drone_tick(1)
<font color="#2AA1B3">:out_of_ticks</font>
</pre>
