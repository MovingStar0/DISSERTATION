breed [human person]
breed [cars car]
breed [cones cone]



globals [
  green-height;
  sidewalk-height ; 人行横宽度
  road-width-left ; 行车道宽度 左
  road-width-right ; 行车道宽度 右
  crosswalk-height ; 人行横道宽度
  max-turtles
  traffic-light-state  ; 红绿灯状态
  last-change-tick; 记录最后一次更变红绿灯的tick
  car-light-state ;行车道红绿灯状态
  filtered-cars-in-range ;需要注意到的车
]

human-own [
  stop-x ;黄色小人停止的x坐标
  stop-tick ;黄色小人停止时的tick
  stopped ; 停止状态
  intend ;想走的方向
  wait-time ;个人等待时间
  car-detected ;检测car存在？
  jaywalk ;是否有jaywalk行为
  cross-over? ;是否已经穿过马路了
]

cars-own [
  speed ;速度
  car-stop?

]

to setup
  clear-all

  ;设置最大小人数
  set max-turtles people

  set green-height 4;
  setup-green

  ; 人行道
  set sidewalk-height 6
  setup-sidewalk

  ; 行车道
  set road-width-left 60
  set road-width-right 20
  setup-roads

  ;斑马线
  set crosswalk-height 20;
  setup-crosswalk

  ;红绿灯
  set last-change-tick 0
  set traffic-light-state red
  set car-light-state green

  setup-traffic-lights
  setup-car-lights


  ;人
  setup-people

  ;车
  setup-cars

  reset-ticks
end

;----------------------------------------------------------
;----------------------------------------------------------
;绿化带
to setup-green
  ask patches with [abs(pycor) <= 20 and abs(pycor) > (20 - green-height)] [
    set pcolor green;
  ]
end

to setup-sidewalk
  ask patches with [abs(pycor) <= (20 - green-height) and abs(pycor) >= (20 - green-height - sidewalk-height)] [
    set pcolor rgb 211 211 211 ; 用白色表示人行横道
  ]
end

to setup-roads
  ask patches with [pycor = 0 and pxcor <= (road-width-left - 50)] [
    set pcolor gray + 2 ; 用灰色表示行车道
  ]

  ask patches with [pycor = 0 and pxcor >= (50 - road-width-right)] [
    set pcolor gray + 2 ; 用灰色表示行车道
  ]
end

to setup-crosswalk
  ask patches with [
    abs(pycor) < (20 - green-height - sidewalk-height)
    and
    pxcor > (road-width-left - 50) and pxcor < (50 - road-width-right)
  ]
  [ set pcolor white]
end


;----------------------------------------------------------
;--------------------------person
; 创建小人并将其放置在步行道上
to setup-people
  create-new-people
end

; 判断turtle是否在步行道上
;to-report is-in-sidewalk?
;  report abs(pycor) <= (20 - green-height) and abs(pycor) >= (20 - green-height - sidewalk-height)
;end
; 判断turtle是否在世界边界之外
to-report is-outside-world?
  report pxcor >= (max-pxcor - 1) or (pxcor < min-pxcor + 1)
end

;-----------------------------------------
; 初始化红绿灯
to setup-traffic-lights
  set traffic-light-state "red"
  ask patches with [pxcor = 28 and pycor = 8] [set pcolor red]
  ask patches with [pxcor = 28 and pycor = 9] [set pcolor red]
  ask patches with [pxcor = 29 and pycor = 8] [set pcolor red]
  ask patches with [pxcor = 29 and pycor = 9] [set pcolor red]

end

to setup-car-lights
  set car-light-state "green"
  ask patches with [pxcor = 11 and pycor = 5] [set pcolor green]
  ask patches with [pxcor = 29 and pycor = -5] [set pcolor green]
end


; 切换红绿灯状态
to toggle-traffic-lights
  ifelse traffic-light-state = "red" [
    set traffic-light-state "green"
    ask patches with [pxcor = 28 and (pycor = 8 or pycor = 9)] [
      set pcolor green
    ]
    ask patches with [pxcor = 29 and (pycor = 8 or pycor = 9)] [
      set pcolor green
    ]
    set last-change-tick ticks
  ]
  [
    set traffic-light-state "red"
    ask patches with [pxcor = 28 and (pycor = 8 or pycor = 9)] [
      set pcolor red
    ]
    ask patches with [pxcor = 29 and (pycor = 8 or pycor = 9)] [
      set pcolor red
    ]
    set last-change-tick ticks
  ]
end

;切换car红绿灯
to toggle-car-lights
  ifelse car-light-state = "green" [
    set car-light-state "red"
    ask patches with [pxcor = 11 and pycor = 5] [set pcolor red]
    ask patches with [pxcor = 29 and pycor = -5] [set pcolor red]
  ] [
    set car-light-state "green"
    ask patches with [pxcor = 11 and pycor = 5] [set pcolor green]
    ask patches with [pxcor = 29 and pycor = -5] [set pcolor green]
  ]
end


; 创建汽车并将其放置在指定车道上
to setup-cars
  ; 记录剩余车数

  ; 在y坐标为5和-5的车道上随机分配汽车
  while [count cars < total-vehicles] [

    ifelse random-float 1 < 0.5 [
      let pos one-of (patches with [pycor = 5])  ; 选择y坐标为5的车道
      create-car-in-position [pxcor] of pos [pycor] of pos 90 cyan
    ] [

      let pos one-of (patches with [pycor = -5])  ; 选择y坐标为5的车道
      create-car-in-position [pxcor] of pos [pycor] of pos 270 cyan
    ]
  ]
end

;创建新汽车，控制距离
to create-car-in-position [x y head vcolor]
  let safe-distance 5
  let position-safe? true

  ask cars with [distancexy x y < safe-distance][ set position-safe? false]

  if position-safe? [
    ifelse head = 90 [
      create-cars 1 [
        set shape "car"
        set size 5
        set color vcolor
        setxy x y
        set heading head  ; 设置行驶方向
        set speed random limit-speed-car + 1 ;初始化速度
        set car-stop? false
      ]
    ][
      create-cars 1 [
      set shape "car2"
      set size 5
      set color vcolor
      setxy x y
      set heading head  ; 设置行驶方向
      set speed random limit-speed-car + 1 ;初始化速度
      set car-stop? false
    ]
    ]

  ]
end

; 小人移动
to move-human-cross [people1]
  set filtered-cars-in-range 0
  ask people1 [
    if pycor < 0 and intend = "none" [
      set intend "up"
      ;set dest one-of [12 15]
      set wait-time ticks - stop-tick
    ]

    if pycor > 0 and intend = "none" [
      set intend "down"
      ;set dest one-of [-11 -14]
      set wait-time ticks - stop-tick
;      set sum-wait-time sum-wait-time + wait-time
    ]

    ;如果在下面
    if intend = "up" [
      set heading 0 ;下面的上移
      forward 1
      ;如果移动到对面马路，往左或往右
      if pycor >= 12 and pycor <= 15 [
        ifelse random-float 1 < 0.5 [
          set heading 90; 右
          set stopped false
          set jaywalk false
          set cross-over? true
          set intend "right"
        ][
          set heading 270; 左
          set stopped false
          set jaywalk false
          set cross-over? true
          set intend "left"
        ]
      ]
    ]

    if intend = "down"[
      ;如果在上面
      set heading 180 ;向下
      forward 1
      if pycor <= -11 and pycor >= -14 [
        ifelse random-float 1 < 0.5 [
          set heading 90
          set stopped false
          set jaywalk false
          set cross-over? true
          set intend "right"
        ][
          set heading 270
          set stopped false
          set jaywalk false
          set cross-over? true
          set intend "left"
        ]
      ]
    ]
  ]

  ;销毁视野范围
  ask cones [die]

end

to create-new-people
  let pos one-of [[-48 15] [-48 12] [48 -14] [48 -11]]
    ; 如果当前turtles数量少于max-turtles，则生成新的小人
  while [count human < max-turtles] [
    create-human 1 [
      setxy item 0 pos item 1 pos
      set stopped false
      set intend "none"
      set shape "person"
      set size 4
      set color red
      set jaywalk false
      set cross-over? false
      set stop-x random 13 + 14 ; 为小人随机分配一个停止的x坐标
    ]
    create-cones 1 [
      set size human-obsv-dis * 2
      set shape "circle"
      setxy item 0 pos item 1 pos
      set color [0 255 0 60]
    ]
  ]


end

to create-new-car
    if count cars < total-vehicles[
    ifelse random-float 1 < 0.5 [
      create-car-in-position -98 5 90 cyan
    ] [
      create-car-in-position 98 -5 270 cyan
    ]
  ]
end

to control-traffic-light
   ; 判断是否需要切换红绿灯状态
  if traffic-light-state = "red" [
    if ticks >= last-change-tick + both-red-light-time
    and car-light-state = "red"
    and ticks < last-change-tick + red-light-time + both-red-light-time
    [
      toggle-car-lights
    ]
    if ticks >= last-change-tick + red-light-time + both-red-light-time[
      if car-light-state = "green" [
        toggle-car-lights
      ]
      if ticks >= last-change-tick + red-light-time + both-red-light-time + both-red-light-time[
        toggle-traffic-lights
      ]

    ]
  ]
  if traffic-light-state = "green" [
    if ticks >= last-change-tick + green-light-time  [
      toggle-traffic-lights
    ]
  ]
end



to go
  let jaywalk-stop? false
  let collision-stop? false
  ask human [
    ;正常行走
   ifelse not jaywalk [

      ; 没stop才走, stop了就不走了
      ifelse not stopped [
        if pycor > 0 [
          ifelse intend = "left" [set heading 270] [set heading 90]
        ]
        if pycor < 0 [
          ifelse intend = "right" [set heading 90] [set heading 270]
        ]
        forward 1
        let he [heading] of self
        ask cones [
          set heading he
          forward 1
        ]
      ] [
        ; 只要行车道是红灯, 并且斑马线上没有车, 就直接走
        if not any? cars with [xcor >= 11 and xcor <= 29 and car-stop? = false] [
          if car-light-state = "red" or not member? pycor [12 15 -11 -14] [
            move-human-cross self
          ]
        ]
      ]

      if in-area? self [
        ; 每次都要转头并观察路况
        if pycor < 0 and intend = "none" [
          set heading 0
          ifelse detected-safe? self [
            ;show "go!"
            set jaywalk true
            set jaywalk-stop? true
          ][
;            show "no go!"
          ]
        ]

        if pycor > 0 and intend = "none" [
          set heading 180
          ifelse detected-safe? self [
            ;show "go!"
            set jaywalk true
            set jaywalk-stop? true
          ][
;            show "no go!"
          ]
        ]
      ]

    ] [
      ; 可以jaywalk
      move-human-cross self
    ]

      ;到路口该停了
      if not stopped and abs(pxcor - stop-x) < 1 and not cross-over?[
        set stopped true
        set stop-tick ticks
        ; 转头并观察路况
        if pycor < 0 and intend = "none" [set heading 0]
        if pycor > 0 and intend = "none" [set heading 180]
      ]

;    if stopped [
;      ;观察时间到，开始过马路
;      if stopped and (ticks - stop-tick >= observation-time )[
;
;        if traffic-light-state = "green" or not member? pycor [12 15 -11 -14] [
;          ; move
;          move-human-cross self
;        ]
;
;        ; 会闯红灯
;        if color = red [
;          ;观察
;          let detected-cars cars in-cone 20 180 ;范围内没车就过
;
;          ifelse any? detected-cars [
;            set car-detected true
;            if intend != "none" [
;              move-human-cross self
;            ]
;          ][
;            set car-detected false
;            move-human-cross self
;          ]
;        ]
;      ]
;    ]
    ; 检查turtle是否走出界面
    if is-outside-world? [die]
  ]


  ; 行车
  ask cars [
    ; 停车
    ; 探测前方的颜色
    let front-patch-ahead-5 patch-ahead 5
    ; 探测前方的 turtle
    let turtles-ahead-10 (cars in-cone 10 30) with [self != myself]
    let turtles-human-ahead-10 (human in-cone 10 30) with [self != myself]
    let turtles-ahead-8 (cars in-cone 8 30) with [self != myself]
    let turtles-ahead-6 (cars in-cone 6 30) with [self != myself]

    if count turtles-ahead-8 > 0 [
      ;如果8范围有车, 车速变为1
      set car-stop? false
      set speed 1
    ]
    if count turtles-ahead-6 > 0 [
      ;如果6范围有车, 车速降为0
      set car-stop? true
      stop
    ]
    if count turtles-ahead-10 = 0 and turtles-human-ahead-10 = 0 [
      ;如果10范围没有车, 速度升
      set car-stop? false
      set speed limit-speed-car
    ]

    ;碰撞
    ; 实时检测前方1格位置，范围为90度
    let detected-people human in-cone 3 90

    ; 如果检测到 people，则同时删除汽车和所有检测到的 people
    if any? detected-people [
      print "die!!"
      set collision-stop? true
      ; 如果想看车祸现场, 就注释下面两行
      ask detected-people [ die ]
      die
    ]

    ; 条件检查
    ; 条件一 没有车祸
    if not collision-stop? [
      ; 条件2 没有红灯或到达边界
      ifelse front-patch-ahead-5 = nobody [
        forward speed
      ][
        ifelse [pcolor] of front-patch-ahead-5 = red[
          set car-stop? true
          stop
        ] [
          ;另外, 探测k范围内是否有红色
          let i 1
          let r [speed] of self
          repeat r [
            let a patch-ahead i
            if a != nobody [
              if [pcolor] of a = red [
                set car-stop? true
                stop
              ]
            ]
            set i i + 1
          ]

          ; 否则前进
          set car-stop? false
          forward speed
        ]
      ]
    ]

    if is-outside-world? [ die ]
  ]




;----------控制人口
create-new-people

;----------控制车辆数量
create-new-car

;----------红绿灯控制
control-traffic-light

;---修改车辆颜色
  ifelse filtered-cars-in-range != 0 [
    if any? filtered-cars-in-range [
      ask filtered-cars-in-range [
        set color [255 0 0 80]
      ]
      ask cars with [not member? self filtered-cars-in-range] [
        set color cyan
      ]
    ]
  ][
    ask cars [
        set color cyan
      ]
  ]


; 暂停
  if jaywalk-stop? and jaywalk-stop-model [ stop ]
  if collision-stop? and collision-stop-model [ stop ]

  tick
end



;---- 是否进入可以jaywalk的区域
to-report in-area? [human1]
  let human-x [xcor] of human1
  ifelse human-x > -100 + human-obsv-dis and human-x < 100 - human-obsv-dis [
    report true
  ][
    report false
  ]
end


;---- 报告横穿马路时的各参数
to report-param [x_p v_c epsilon_vc epsilon_xp t_c real_tc]
  let x-dis x_p
  let x-speed v_c
  let er-speed epsilon_vc
  let er-dis epsilon_xp
  let x-t t_c
  let real-time real_tc
  show (word "gus dis: " x_p " gus speed: " v_c " error speed: " epsilon_vc " error dis: " epsilon_xp " gus time: " t_c " real time: " real_tc)

end

;---- jaywalk
to-report detected-safe? [human1]
  let human-x [xcor] of human1
  let human-y [ycor] of human1
  let cars-in-range cars in-cone human-obsv-dis 180

  set filtered-cars-in-range cars-in-range with [
    (ifelse-value ([ycor] of self > 0)
      [xcor <= human-x]
      [xcor >= human-x])
  ]

  ifelse any? filtered-cars-in-range [

    let closest-car min-one-of filtered-cars-in-range [distance human1]

    let car-x [xcor] of closest-car
    let car-y [ycor] of closest-car

    let real-xp abs(car-x - human-x) ;人与车的横向距离
    let real-vc [speed] of closest-car ;车的速度

    let real-dp 0
    ifelse human-y > 0 [
      set real-dp abs(human-y - -11) ;人距离马路对面的距离
    ] [
      set real-dp abs(human-y - 12) ;人距离马路对面的距离
    ]

    let real-vp 1;人过马路的速度

    ifelse not deviation? [
      ;计算车到达的时间
      let real-v-t real-xp / real-vc ;车到达的时间
      let real-p-t real-dp / real-vp ;人到达对面的时间

      ifelse real-v-t > real-p-t [
        show (word "safe to cross " real-v-t ">" real-p-t)
        report true
      ] [
        ;show (word "accident risk " real-v-t "<" real-p-t)
        report false
      ]
    ] [
      ;加上误差

      ; 定义均值
      let mu_xp 0
      let mu_vc 0

      ; 定义标准差
      let sigma_xp 2  ; 假设2米的误差
      let sigma_vc 0.1  ; 假设2公里/小时的误差



      ; 生成误差
      let epsilon_xp random-normal 0 sigma_xp
      let epsilon_vc random-normal 0 sigma_vc


      ; 计算目测值
      let x_p (real-xp + epsilon_xp)
      let v_c (real-vc + epsilon_vc)



      ; 计算目测和真实的到达时间
      let t_c x_p / v_c ;车到达的时间
      let real_tc real-xp / real-vc ;真实车到达的时间
      let real_tp real-dp / real-vp ;真实人通过的时间


      ; 判断是否安全过马路
      ifelse t_c > real_tp [ ; 目测车到达的时间大于人通过的时间, 安全
        ifelse real_tc > real_tp [
          show (word "gus safe " t_c ">" real_tp " and real safe to cross " real_tc ">" real_tp )
          report-param x_p v_c epsilon_vc epsilon_xp t_c real_tc
          report true
        ] [
          show (word "maybe safe to cross " t_c ">" real_tp )
          report-param x_p v_c epsilon_vc epsilon_xp t_c real_tc
          report true
        ]



      ] [
;        show (word "not safe to cross " t_c "<" real_tp )
;        report-param x_p v_c epsilon_vc epsilon_xp
        report false
      ]
    ]
  ][
    show (word "no cars, safe to cross ")
    report true
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
18
10
2639
552
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-100
100
-20
20
0
0
1
ticks
60.0

BUTTON
1018
578
1101
611
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1019
616
1101
649
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1124
577
1296
610
red-light-time
red-light-time
1
100
46.0
1
1
NIL
HORIZONTAL

SLIDER
1123
619
1295
652
green-light-time
green-light-time
1
100
46.0
1
1
NIL
HORIZONTAL

INPUTBOX
824
581
887
641
People
1.0
1
0
Number

INPUTBOX
895
581
1000
641
total-vehicles
15.0
1
0
Number

SLIDER
1310
576
1491
609
both-red-light-time
both-red-light-time
1
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1309
617
1481
650
observation-time
observation-time
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
1505
577
1677
610
limit-speed-car
limit-speed-car
1
7
5.0
1
1
NIL
HORIZONTAL

SLIDER
1512
624
1684
657
human-obsv-dis
human-obsv-dis
20
60
40.0
1
1
NIL
HORIZONTAL

SWITCH
1709
571
1891
604
jaywalk-stop-model
jaywalk-stop-model
1
1
-1000

SWITCH
1706
616
1902
649
collision-stop-model
collision-stop-model
1
1
-1000

SWITCH
1979
584
2191
617
deviation?
deviation?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car2
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
