<pre>Interactive Elixir (1.17.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)&gt; {:ok, pid} = BigMarsh.V1Simulator.start_link([])
{<font color="#2AA1B3">:ok</font>,<font color="#A2734C"> #PID&lt;0.190.0&gt;</font>}
iex(2)&gt; 
<font color="#A347BA">nil</font>
iex(3)&gt;  GenServer.cast(pid, {:add_drone_type, &quot;test&quot;, 30.0, 10.0, 2.0, 5.0})
<font color="#2AA1B3">:ok</font>
iex(4)&gt; GenServer.cast(pid, {:add_drone, 1, &quot;test&quot;, -87.64218256846847, 41.68516340084044, 100.0, -87.61144234984356, 41.685561808243065, 30.0})
<font color="#2AA1B3">:ok</font>
iex(5)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.63734922604256</font>,<font color="#A2734C"> 41.685226586222846</font>,<font color="#A2734C"> 96.82</font>}
iex(6)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.63251587413875</font>,<font color="#A2734C"> 41.6852895691031</font>,<font color="#A2734C"> 94.13999999999999</font>}
iex(7)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.62768251278743</font>,<font color="#A2734C"> 41.68535234948036</font>,<font color="#A2734C"> 91.95999999999998</font>}
iex(8)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.62284914201899</font>,<font color="#A2734C"> 41.6854149273538</font>,<font color="#A2734C"> 90.27999999999997</font>}
iex(9)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.61801576186382</font>,<font color="#A2734C"> 41.68547730272256</font>,<font color="#A2734C"> 89.09999999999997</font>}
iex(10)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.61318237235228</font>,<font color="#A2734C"> 41.685539475585806</font>,<font color="#A2734C"> 88.41999999999996</font>}
iex(11)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.61144234984356</font>,<font color="#A2734C"> 41.685561808243065</font>,<font color="#A2734C"> 88.23999999999995</font>}
iex(12)&gt; GenServer.call(pid, {:tick_drone, 1})
<font color="#2AA1B3">:out_of_ticks</font>
iex(13)&gt; GenServer.call(pid, {:tick_drone, 1})
<font color="#2AA1B3">:out_of_ticks</font>
iex(14)&gt; GenServer.cast(pid, {:new_location_target, 1, -87.64218256846847, 41.68516340084044 , 30.0})
<font color="#2AA1B3">:ok</font>
iex(15)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.61627574271593</font>,<font color="#A2734C"> 41.685499708281995</font>,<font color="#A2734C"> 85.05999999999995</font>}
iex(16)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.62110912624289</font>,<font color="#A2734C"> 41.68543740581512</font>,<font color="#A2734C"> 82.37999999999994</font>}
iex(17)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.62594250039405</font>,<font color="#A2734C"> 41.68537490084328</font>,<font color="#A2734C"> 80.19999999999993</font>}
iex(18)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.63077586513903</font>,<font color="#A2734C"> 41.68531219336729</font>,<font color="#A2734C"> 78.51999999999992</font>}
iex(19)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.63560922044744</font>,<font color="#A2734C"> 41.68524928338801</font>,<font color="#A2734C"> 77.33999999999992</font>}
iex(20)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.6404425662889</font>,<font color="#A2734C"> 41.68518617090629</font>,<font color="#A2734C"> 76.65999999999991</font>}
iex(21)&gt; GenServer.call(pid, {:tick_drone, 1})
{<font color="#A2734C">-87.64218256846847</font>,<font color="#A2734C"> 41.68516340084044</font>,<font color="#A2734C"> 76.4799999999999</font>}
iex(22)&gt; GenServer.call(pid, {:tick_drone, 1})
<font color="#2AA1B3">:out_of_ticks</font>
iex(23)&gt; GenServer.cast(pid, {:new_location_target, 1, -87.64218256846847, 41.68516340084044 , 30.0})
<font color="#2AA1B3">:ok</font>
iex(24)&gt; GenServer.cast(pid, {:new_location_target, 1, -87.64218256846847, 41.68516340084044 , 30.0})
<font color="#2AA1B3">:ok</font>
iex(25)&gt; GenServer.cast(pid, {:new_location_target, 1, -87.64218256846847, 41.68516340084044 , 30.0})
<font color="#2AA1B3">:ok</font>
iex(26)&gt; GenServer.call(pid, {:tick_drone, 1})
<font color="#2AA1B3">:out_of_ticks</font>
</pre>
