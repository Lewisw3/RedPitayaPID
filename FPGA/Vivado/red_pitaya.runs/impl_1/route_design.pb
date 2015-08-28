
h
Command: %s
53*	vivadotcl2@
,route_design -directive MoreGlobalIterations2default:defaultZ4-113
š
@Attempting to get a license for feature '%s' and/or device '%s'
308*common2"
Implementation2default:default2
xc7z0102default:defaultZ17-347
Š
0Got license for feature '%s' and/or device '%s'
310*common2"
Implementation2default:default2
xc7z0102default:defaultZ17-349
g
,Running DRC as a precondition to command %s
22*	vivadotcl2 
route_design2default:defaultZ4-22
G
Running DRC with %s threads
24*drc2
22default:defaultZ23-27
Y
DRC finished with %s
79*	vivadotcl2(
0 Errors, 1 Warnings2default:defaultZ4-198
\
BPlease refer to the DRC report (report_drc) for more information.
80*	vivadotclZ4-199
M

Starting %s Task
103*constraints2
Routing2default:defaultZ18-103
_
Using Router directive '%s'.
104*route2(
MoreGlobalIterations2default:defaultZ35-270
p
BMultithreading enabled for route_design using a maximum of %s CPUs97*route2
22default:defaultZ35-254
K

Starting %s Task
103*constraints2
Route2default:defaultZ18-103
g

Phase %s%s
101*constraints2
1 2default:default2#
Build RT Design2default:defaultZ18-101
x

Phase %s%s
101*constraints2
1.1 2default:default22
Build Netlist & NodeGraph (MT)2default:defaultZ18-101
K
?Phase 1.1 Build Netlist & NodeGraph (MT) | Checksum: 15dcbf3ed
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:22 ; elapsed = 00:00:10 . Memory (MB): peak = 909.996 ; gain = 75.5002default:default
:
.Phase 1 Build RT Design | Checksum: 1212a27e2
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:22 ; elapsed = 00:00:11 . Memory (MB): peak = 909.996 ; gain = 75.5002default:default
m

Phase %s%s
101*constraints2
2 2default:default2)
Router Initialization2default:defaultZ18-101
f

Phase %s%s
101*constraints2
2.1 2default:default2 
Create Timer2default:defaultZ18-101
9
-Phase 2.1 Create Timer | Checksum: 1212a27e2
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:22 ; elapsed = 00:00:11 . Memory (MB): peak = 909.996 ; gain = 75.5002default:default
i

Phase %s%s
101*constraints2
2.2 2default:default2#
Restore Routing2default:defaultZ18-101
<
0Phase 2.2 Restore Routing | Checksum: 1212a27e2
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:22 ; elapsed = 00:00:11 . Memory (MB): peak = 912.156 ; gain = 77.6602default:default
m

Phase %s%s
101*constraints2
2.3 2default:default2'
Special Net Routing2default:defaultZ18-101
@
4Phase 2.3 Special Net Routing | Checksum: 171fd7097
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:23 ; elapsed = 00:00:11 . Memory (MB): peak = 919.098 ; gain = 84.6022default:default
q

Phase %s%s
101*constraints2
2.4 2default:default2+
Local Clock Net Routing2default:defaultZ18-101
C
7Phase 2.4 Local Clock Net Routing | Checksum: fa7545fb
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:23 ; elapsed = 00:00:11 . Memory (MB): peak = 919.098 ; gain = 84.6022default:default
g

Phase %s%s
101*constraints2
2.5 2default:default2!
Update Timing2default:defaultZ18-101
w

Phase %s%s
101*constraints2
2.5.1 2default:default2/
Update timing with NCN CRPR2default:defaultZ18-101
l

Phase %s%s
101*constraints2
2.5.1.1 2default:default2"
Hold Budgeting2default:defaultZ18-101
>
2Phase 2.5.1.1 Hold Budgeting | Checksum: fa7545fb
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:26 ; elapsed = 00:00:13 . Memory (MB): peak = 920.117 ; gain = 85.6212default:default
I
=Phase 2.5.1 Update timing with NCN CRPR | Checksum: fa7545fb
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:26 ; elapsed = 00:00:13 . Memory (MB): peak = 920.117 ; gain = 85.6212default:default
9
-Phase 2.5 Update Timing | Checksum: fa7545fb
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:26 ; elapsed = 00:00:13 . Memory (MB): peak = 920.117 ; gain = 85.6212default:default
~
Estimated Timing Summary %s
57*route2J
6| WNS=0.226  | TNS=0      | WHS=-0.253 | THS=-37.5  |
2default:defaultZ35-57
c

Phase %s%s
101*constraints2
2.6 2default:default2
	Budgeting2default:defaultZ18-101
5
)Phase 2.6 Budgeting | Checksum: fa7545fb
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:28 ; elapsed = 00:00:14 . Memory (MB): peak = 920.117 ; gain = 85.6212default:default
?
3Phase 2 Router Initialization | Checksum: fa7545fb
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:28 ; elapsed = 00:00:14 . Memory (MB): peak = 920.117 ; gain = 85.6212default:default
g

Phase %s%s
101*constraints2
3 2default:default2#
Initial Routing2default:defaultZ18-101
9
-Phase 3 Initial Routing | Checksum: 10fa22e3
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:29 ; elapsed = 00:00:15 . Memory (MB): peak = 920.137 ; gain = 85.6412default:default
j

Phase %s%s
101*constraints2
4 2default:default2&
Rip-up And Reroute2default:defaultZ18-101
l

Phase %s%s
101*constraints2
4.1 2default:default2&
Global Iteration 02default:defaultZ18-101
k

Phase %s%s
101*constraints2
4.1.1 2default:default2#
Remove Overlaps2default:defaultZ18-101
Ö
ûThe following overlapped %s exist in the design and there is low overall congestion. 
Resolution: Check for routing resource conflicts on the identified nets or significant localized congestion using the Route Congestion Metrics in the Device View. %s125*route2
nodes2default:default2¤

1. INT_R_X19Y58/IMUX42
Overlapping nets: 2
	i_pid/n_0_sys_rdata_o[18]_INST_0_i_9
	i_pid/n_0_sys_rdata_o[18]_INST_0_i_10
2. INT_R_X5Y39/IMUX42
Overlapping nets: 2
	i_ams/dac_c_o[9]
	i_ams/dac_c_o[11]
3. INT_R_X5Y39/IMUX46
Overlapping nets: 2
	i_ams/dac_c_o[6]
	i_ams/dac_c_o[10]
4. INT_L_X18Y59/EL1BEG1
Overlapping nets: 2
	i_pid/n_0_sys_rdata_o[13]_INST_0_i_6
	i_pid/n_0_sys_rdata_o[18]_INST_0_i_9
2default:defaultZ35-325
=
1Phase 4.1.1 Remove Overlaps | Checksum: 4ca3f108
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:38 ; elapsed = 00:00:21 . Memory (MB): peak = 920.793 ; gain = 86.2972default:default
i

Phase %s%s
101*constraints2
4.1.2 2default:default2!
Update Timing2default:defaultZ18-101
;
/Phase 4.1.2 Update Timing | Checksum: 4ca3f108
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:39 ; elapsed = 00:00:21 . Memory (MB): peak = 922.113 ; gain = 87.6172default:default
~
Estimated Timing Summary %s
57*route2J
6| WNS=-0.0796| TNS=-0.241 | WHS=N/A    | THS=N/A    |
2default:defaultZ35-57
p

Phase %s%s
101*constraints2
4.1.3 2default:default2(
collectNewHoldAndFix2default:defaultZ18-101
C
7Phase 4.1.3 collectNewHoldAndFix | Checksum: 15bd227fd
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:39 ; elapsed = 00:00:22 . Memory (MB): peak = 922.113 ; gain = 87.6172default:default
m

Phase %s%s
101*constraints2
4.1.4 2default:default2%
GlobIterForTiming2default:defaultZ18-101
k

Phase %s%s
101*constraints2
4.1.4.1 2default:default2!
Update Timing2default:defaultZ18-101
>
2Phase 4.1.4.1 Update Timing | Checksum: 1741bd728
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:39 ; elapsed = 00:00:22 . Memory (MB): peak = 922.113 ; gain = 87.6172default:default
g

Phase %s%s
101*constraints2
4.1.4.2 2default:default2
	Budgeting2default:defaultZ18-101
:
.Phase 4.1.4.2 Budgeting | Checksum: 1741bd728
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:41 ; elapsed = 00:00:23 . Memory (MB): peak = 924.152 ; gain = 89.6562default:default
@
4Phase 4.1.4 GlobIterForTiming | Checksum: 1222c7df6
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:41 ; elapsed = 00:00:23 . Memory (MB): peak = 924.152 ; gain = 89.6562default:default
?
3Phase 4.1 Global Iteration 0 | Checksum: 1222c7df6
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:41 ; elapsed = 00:00:23 . Memory (MB): peak = 924.152 ; gain = 89.6562default:default
l

Phase %s%s
101*constraints2
4.2 2default:default2&
Global Iteration 12default:defaultZ18-101
k

Phase %s%s
101*constraints2
4.2.1 2default:default2#
Remove Overlaps2default:defaultZ18-101
>
2Phase 4.2.1 Remove Overlaps | Checksum: 133b78484
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:43 ; elapsed = 00:00:25 . Memory (MB): peak = 925.078 ; gain = 90.5822default:default
i

Phase %s%s
101*constraints2
4.2.2 2default:default2!
Update Timing2default:defaultZ18-101
<
0Phase 4.2.2 Update Timing | Checksum: 133b78484
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:44 ; elapsed = 00:00:25 . Memory (MB): peak = 925.078 ; gain = 90.5822default:default
~
Estimated Timing Summary %s
57*route2J
6| WNS=0.125  | TNS=0      | WHS=N/A    | THS=N/A    |
2default:defaultZ35-57
p

Phase %s%s
101*constraints2
4.2.3 2default:default2(
collectNewHoldAndFix2default:defaultZ18-101
B
6Phase 4.2.3 collectNewHoldAndFix | Checksum: 907c74fd
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:44 ; elapsed = 00:00:25 . Memory (MB): peak = 925.078 ; gain = 90.5822default:default
>
2Phase 4.2 Global Iteration 1 | Checksum: 907c74fd
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:44 ; elapsed = 00:00:25 . Memory (MB): peak = 925.078 ; gain = 90.5822default:default
<
0Phase 4 Rip-up And Reroute | Checksum: 907c74fd
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:44 ; elapsed = 00:00:25 . Memory (MB): peak = 925.078 ; gain = 90.5822default:default
e

Phase %s%s
101*constraints2
5 2default:default2!
Delay CleanUp2default:defaultZ18-101
g

Phase %s%s
101*constraints2
5.1 2default:default2!
Update Timing2default:defaultZ18-101
9
-Phase 5.1 Update Timing | Checksum: 907c74fd
*common
†

%s
*constraints2o
[Time (s): cpu = 00:00:45 ; elapsed = 00:00:26 . Memory (MB): peak = 925.078 ; gain = 90.5822default:default
~
Estimated Timing Summary %s
57*route2J
6| WNS=0.125  | TNS=0      | WHS=N/A    | THS=N/A    |
2default:defaultZ35-57
8
,Phase 5 Delay CleanUp | Checksum: 1598b0454
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:49 ; elapsed = 00:00:28 . Memory (MB): peak = 942.293 ; gain = 107.7972default:default
e

Phase %s%s
101*constraints2
6 2default:default2!
Post Hold Fix2default:defaultZ18-101
l

Phase %s%s
101*constraints2
6.1 2default:default2&
Full Hold Analysis2default:defaultZ18-101
i

Phase %s%s
101*constraints2
6.1.1 2default:default2!
Update Timing2default:defaultZ18-101
<
0Phase 6.1.1 Update Timing | Checksum: 1598b0454
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:50 ; elapsed = 00:00:29 . Memory (MB): peak = 942.293 ; gain = 107.7972default:default
~
Estimated Timing Summary %s
57*route2J
6| WNS=0.125  | TNS=0      | WHS=-0.103 | THS=-0.103 |
2default:defaultZ35-57
?
3Phase 6.1 Full Hold Analysis | Checksum: 1598b0454
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:50 ; elapsed = 00:00:29 . Memory (MB): peak = 942.293 ; gain = 107.7972default:default
8
,Phase 6 Post Hold Fix | Checksum: 1618b16e5
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:50 ; elapsed = 00:00:29 . Memory (MB): peak = 942.293 ; gain = 107.7972default:default
m

Phase %s%s
101*constraints2
7 2default:default2)
Verifying routed nets2default:defaultZ18-101
@
4Phase 7 Verifying routed nets | Checksum: 1618b16e5
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:50 ; elapsed = 00:00:29 . Memory (MB): peak = 943.277 ; gain = 108.7812default:default
i

Phase %s%s
101*constraints2
8 2default:default2%
Depositing Routes2default:defaultZ18-101
<
0Phase 8 Depositing Routes | Checksum: 127274ef6
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:51 ; elapsed = 00:00:30 . Memory (MB): peak = 943.277 ; gain = 108.7812default:default
j

Phase %s%s
101*constraints2
9 2default:default2&
Post Router Timing2default:defaultZ18-101

Post Routing Timing Summary %s
20*route2J
6| WNS=0.128  | TNS=0.000  | WHS=0.057  | THS=0.000  |
2default:defaultZ35-20
=
'The design met the timing requirement.
61*routeZ35-61
=
1Phase 9 Post Router Timing | Checksum: 127274ef6
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:55 ; elapsed = 00:00:32 . Memory (MB): peak = 943.277 ; gain = 108.7812default:default
4
Router Completed Successfully
16*routeZ35-16
4
(Ending Route Task | Checksum: 127274ef6
*common
‡

%s
*constraints2p
\Time (s): cpu = 00:00:00 ; elapsed = 00:00:32 . Memory (MB): peak = 943.277 ; gain = 108.7812default:default
‡

%s
*constraints2p
\Time (s): cpu = 00:00:00 ; elapsed = 00:00:32 . Memory (MB): peak = 943.277 ; gain = 108.7812default:default
Q
Releasing license: %s
83*common2"
Implementation2default:defaultZ17-83
½
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
622default:default2
22default:default2
02default:default2
02default:defaultZ4-41
U
%s completed successfully
29*	vivadotcl2 
route_design2default:defaultZ4-42
ü
I%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s
268*common2"
route_design: 2default:default2
00:00:562default:default2
00:00:322default:default2
943.2772default:default2
111.6602default:defaultZ17-268
G
Running DRC with %s threads
24*drc2
22default:defaultZ23-27
©
#The results of DRC are in file %s.
168*coretcl2è
hC:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.runs/impl_1/red_pitaya_top_drc_routed.rpthC:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.runs/impl_1/red_pitaya_top_drc_routed.rpt2default:default8Z2-168
\
+Creating Default Power Bel for instance %s
23*power2
i_DNA2default:defaultZ33-23
B
,Running Vector-less Activity Propagation...
51*powerZ33-51
G
3
Finished Running Vector-less Activity Propagation
1*powerZ33-1
 
âMMCM/PLL RST static_probability should be either 0 or 1, power analysis is using 0 by default.
Use 'set_switching_activity -static_probability 1 -signal_rate 0 [get_nets %s]'  to set the static_probabiblity to '1'  if desired.207*power2#
i_analog/RESET02default:defaultZ33-218
ú
I%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s
268*common2"
report_power: 2default:default2
00:00:142default:default2
00:00:092default:default2
943.2772default:default2
0.0002default:defaultZ17-268
€
UpdateTimingParams:%s.
91*timing2P
< Speed grade: -1, Delay Type: min_max, Constraints type: SDC2default:defaultZ38-91
s
CMultithreading enabled for timing update using a maximum of %s CPUs155*timing2
22default:defaultZ38-191
4
Writing XDEF routing.
211*designutilsZ20-211
A
#Writing XDEF routing logical nets.
209*designutilsZ20-209
A
#Writing XDEF routing special nets.
210*designutilsZ20-210

I%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s
268*common2)
Write XDEF Complete: 2default:default2
00:00:012default:default2
00:00:012default:default2
943.2772default:default2
0.0002default:defaultZ17-268


End Record