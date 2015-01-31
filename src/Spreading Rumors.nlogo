extensions [nw matrix]

; every user of social networks onw
turtles-own [
  index-age
  chance-of-abstention
  seen?
  tmp-seen?
  shared?
  tmp-shared?
] 

globals [
  highest-degree-node
  
  ;social network variables
  count-turtles-grouped-by-age
  age-distribution
  
  ;tests
  run-res
  filename
  weibull-values
  one-minus-weibull-values
    
  ;constants
  SPREAD-NOT-FINISHED-YET
]


to-report find-node-with-highest-degree
  let highest-node 0
  let highest-degree -1
  ask turtles [
    if (count link-neighbors > highest-degree) [
      set highest-node self
      set highest-degree (count link-neighbors)
    ]
  ]
  report highest-node
end

to color-patches
  ask patches[
    set pcolor white
  ]
end

; this function will be invoked inside a turtle context
to set-default-turtle
  set seen? false
  set shared? false
  set tmp-seen? false
  set tmp-shared? false
  
  ;some graphics settings
  set color black + 1
  set label-color green - 1
  set label ""
end


to reset-plots
  set run-res [ 0 0 0 0 0 ]
  calc-weibull
  clear-all-plots
end

to create-new-graph 
  clear-all
  color-patches
  
  set SPREAD-NOT-FINISHED-YET -1
    
  ;Generates a new network using the Barabàsi Albert algorithm.
  nw:generate-preferential-attachment turtles links num-nodes [
    set heading 0
    set size ((sqrt (count link-neighbors)) * min-node-size)
    set shape "person"
    set-default-turtle
  ]
    
  ; find highest degree turtle
  set highest-degree-node find-node-with-highest-degree
  my-layout-radial
end

to import-graphml-file 
  clear-all
  color-patches
  
  set SPREAD-NOT-FINISHED-YET -1
  
  set num-nodes 0
  nw:load-graphml (word "graphml/" graphml-file) [
    set num-nodes num-nodes + 1
    set heading 0
    set size ((sqrt (count link-neighbors)) * min-node-size)
    set shape "person"
    set-default-turtle
  ]
  
  ; find highest degree turtle
  set highest-degree-node find-node-with-highest-degree
  my-layout-radial
end


; http://www.statista.com/statistics/274829/age-distribution-of-active-social-media-users-worldwide-by-platform/
to setup-age-distribution
  
  if (count turtles != num-nodes) [
    show "num-nodes are changed. Please redo the 'setup-SN-globals' procedure!"
    stop 
  ]
  
  let ages 0
  if (social-network-type = "facebook") [
    set ages [25 29 22 15 9]
  ]
  if (social-network-type = "twitter") [
    set ages [30 31 21 12 6]
  ]
  if (social-network-type = "googleplus") [
    set ages [29 31 20 13 7]
  ]
  if social-network-type = "custom Social Network" [
    set ages (list %-16-24 %-25-34 %-35-44 %-45-54 %-55-64)
    
;    set ages lput %-16-24 []
;    set ages lput %-25-34 ages
;    set ages lput %-35-44 ages
;    set ages lput %-45-54 ages
;    set ages lput %-55-64 ages
  ]
  
  if  (sum ages != 100) [
    error (word "The sum of percentages is not equal to 100%.\n\n" %-16-24" + "%-25-34" + "%-35-44" + "%-45-54" + "%-55-64" = "sum ages)
  ]  
    
  let index 0
  set age-distribution []
  set count-turtles-grouped-by-age []
  foreach ages [
    set count-turtles-grouped-by-age lput ((num-nodes / 100) * ?) count-turtles-grouped-by-age
    set age-distribution sentence age-distribution (n-values ((num-nodes / 100) * ?) [index])    
    set index (index + 1)
  ]
  
  set age-distribution shuffle age-distribution
  ask turtles [
    set index-age item who age-distribution
  ]
end

to setup-turtles
  
  if (count turtles != num-nodes) [
    show "num-nodes are changed. Please redo the 'setup-SN-globals' procedure!"
    stop 
  ]
  
  ; setup standard turtle
  ask turtles [
    set-default-turtle
     
    set chance-of-abstention (random-float 1.0)
    
    ; set shape of Social Network
    if (social-network-type != "custom Social Network")[ set shape social-network-type ]
  ]
  
  ; setup highest degree turtle
  ask highest-degree-node [
    set color orange
    set seen? true
    set shared? true
    set tmp-seen? false
    set tmp-shared? false
  ]
  
  reset-plots
  reset-ticks
end



to go
  let z core
  
  if (z != SPREAD-NOT-FINISHED-YET) [
    if (sum z = num-nodes) [
      show "Every turtle seen news!!!"
    ]
    stop
  ]
  tick 
end

to reset-last-run
  
  ; setup standard turtle
  ask turtles [
    set-default-turtle
  ]
  ; setup highest degree turtle
  ask highest-degree-node [
    set color orange
    set seen? true
    set shared? true
    set tmp-seen? false
    set tmp-shared? false
  ]
  
  reset-plots
  reset-ticks
end



; ######################################################################
; ######################################################################
;     Core of computation and function that do average of all runs
; ######################################################################
; ######################################################################

to-report core
  ifelse (all? turtles [seen?]) [
    report calculate-seen-foreach-group-of-age
  ][
    ask turtles with [not seen?] [
      if(any? (link-neighbors with [shared?])) [
        set tmp-seen? true
        let p-news 0
        if (index-age = 0) [ set p-news p-16-24 ]
        if (index-age = 1) [ set p-news p-25-34 ]
        if (index-age = 2) [ set p-news p-35-44 ]
        if (index-age = 3) [ set p-news p-45-54 ]
        if (index-age = 4) [ set p-news p-55-64 ]
                
        ifelse (p-news > chance-of-abstention) [
          set tmp-shared? true
        ] [
          set label (word "age " index-age " - abstention: " (precision chance-of-abstention 2) )
        ]
      ]
    ]
    
    if (count turtles with [tmp-seen?] = 0) [
      report calculate-seen-foreach-group-of-age
    ]
    
    ask turtles with [tmp-seen?] [
      set tmp-seen? false
      set seen? true
      set color one-of[yellow]
    ]
    ask turtles with [tmp-shared?] [
      set tmp-shared? false
      set shared? true

      set color one-of[green]
    ]
    report SPREAD-NOT-FINISHED-YET
  ]
end

to-report calculate-seen-foreach-group-of-age
  let core-res [ ]
  foreach n-values 5 [?] [
    set core-res lput (count turtles with [seen? and index-age = ?]) core-res
  ]
  report core-res
end

to-report run-test [ times ]
    
  let run-sum [ 0 0 0 0 0 ]
  let index 0
      
  while [index < times] [
    
    if (shuffle-ages-each-run) [
      set age-distribution shuffle age-distribution
      ask turtles [
        set index-age item who age-distribution
      ]
    ]
    ; setup standard turtle
    ask turtles [
      set-default-turtle
      
      set chance-of-abstention (random-float 1.0)
    ]
    
    ; setup highest degree turtle
    ask highest-degree-node [
      set color orange
      set seen? true
      set shared? true
      set tmp-seen? false
      set tmp-shared? false
    ]
    
    let z SPREAD-NOT-FINISHED-YET
    while [z = SPREAD-NOT-FINISHED-YET] [
      set z core
    ]
    
    let temp []
    ( foreach run-sum z[ 
        set temp lput (?1 + ?2) temp 
      ]
    )
    set run-sum temp
    set index index + 1
  ]  
  
  let temp []
  foreach run-sum [ 
    set temp lput (? / times) temp
  ]
  
  report temp
end



; ######################################################################
; ######################################################################
;      Average of 100 runs with the following three configurations
; ######################################################################
; ######################################################################


to average-100-only-p-16-24
  
  reset-plots
  reset-ticks
  
  let step-float 0.05
  
  while [ticks * step-float <= 1.0] [    
    set p-16-24 (ticks * step-float)
    set run-res run-test 100    
    tick
  ]
end

to average-100-p-16-24-and-25-34
  
  ;file-close
  ;stop
  
  reset-plots
  reset-ticks
  
  request-output-file
  if (not is-string? filename) [ error "File does not exist." ]
  
  let step-float 0.05
  
  ; record the columns names
  let temp 0
  let col-names []
  while [temp * step-float <= 1.0] [  
    set col-names lput (temp * step-float) col-names
    set temp (temp + 1)
  ]
  write-csv filename col-names
  
  ; for each probabilities
  let i-p-16-24 0
  while [i-p-16-24 * step-float <= 1.0] [
    
    set p-16-24 (i-p-16-24 * step-float)
    let runs-values (list (i-p-16-24 * step-float))
    
    let i-p-25-34 0
    while [i-p-25-34 * step-float <= 1.0] [
      set p-25-34 (i-p-25-34 * step-float)    
      set run-res run-test 100
      set runs-values lput (sum run-res) runs-values
      set i-p-25-34 (i-p-25-34 + 1)
    ]
    
    write-csv filename runs-values
    
    set i-p-16-24 (i-p-16-24 + 1)
  ]
  file-close
end

to average-100-p-16-to-64-diagonal
  reset-plots
  reset-ticks
  
  request-output-file  
  if (not is-string? filename) [ error "File does not exist." ]
  ; record the columns names
  write-csv filename (list "" "p-16-24" "p-25-34" "p-35-44" "p-45-54" "p-55-64")
  
  let step-float 0.05
  
  while [ticks * step-float <= 1.0] [
    
    set p-16-24 (ticks * step-float)
    set p-25-34 (ticks * step-float)
    set p-35-44 (ticks * step-float)
    set p-45-54 (ticks * step-float)
    set p-55-64 (ticks * step-float)
    
    set run-res run-test 100
    
    let p0 item 0 run-res
    let p1 (item 1 run-res) + p0
    let p2 (item 2 run-res) + p1
    let p3 (item 3 run-res) + p2
    let p4 (item 4 run-res) + p3
    
    write-csv filename (list (ticks * step-float) p0 p1 p2 p3 p4)
    tick
  ]
  file-close
end


; ######################################################################
; ######################################################################
;  Many users who share little in comparison a few users who share more
; ######################################################################
; ######################################################################


to-report random-weibull [alpha beta]
  let x random-float 1
  let y 1 / beta
  let r alpha * (-1 * ln(1 - x)) ^ y
  ifelse (r < 0 or r > 1) [
    report random-weibull alpha beta
  ] [
    report r
  ]  
end

to calc-weibull
  ifelse (weibull-alpha-great-sharers = weibull-alpha-little-sharers) [
    set weibull-values n-values 1000000 [(random-weibull weibull-alpha-great-sharers weibull-beta) ]
    set one-minus-weibull-values (map [1 - ?] weibull-values)
  ] [
    set weibull-values n-values 1000000 [(random-weibull weibull-alpha-great-sharers weibull-beta) ]
    set one-minus-weibull-values n-values 1000000 [1 - (random-weibull weibull-alpha-little-sharers weibull-beta) ]
  ]
end

to-report run-test-chance-of-abstention [ times ]
    
  let run-sum [ 0 0 0 0 0 ]
  let index 0
      
  while [index < times] [
    
    if (shuffle-ages-each-run) [
      set age-distribution shuffle age-distribution
      ask turtles [
        set index-age item who age-distribution
      ]
    ]
    ; setup standard turtle and chance-of-abstention for the "many users group"
    ask turtles with [index-age = 0][
      set-default-turtle      
      set chance-of-abstention (1 - (random-weibull weibull-alpha-little-sharers weibull-beta))
    ]
    ; setup standard turtle and chance-of-abstention for the "few users group"
    ask turtles with [index-age = 4][
      set-default-turtle
      set chance-of-abstention (random-weibull weibull-alpha-great-sharers weibull-beta)
    ]
    
    ; setup highest degree turtle
    ask highest-degree-node [
      set color orange
      set seen? true
      set shared? true
      set tmp-seen? false
      set tmp-shared? false
    ]
    
    let z SPREAD-NOT-FINISHED-YET
    while [z = SPREAD-NOT-FINISHED-YET] [
      set z core
    ]
    
    let temp []
    ( foreach run-sum z[ 
        set temp lput (?1 + ?2) temp 
      ]
    )
    set run-sum temp
    set index index + 1
  ]  
  
  let temp []
  foreach run-sum [ 
    set temp lput (? / times) temp
  ]
  
  report temp
end

to great-sharers-in-comparison-to-little-sharers
  
  set social-network-type "custom Social Network"
  set %-16-24 polulation-%-little-sharers
  set %-25-34 0
  set %-35-44 0
  set %-45-54 0
  set %-55-64 polulation-%-great-sharers
  
  setup-age-distribution
  setup-turtles
    
  set p-16-24 strength-of-rumor
  set p-55-64 strength-of-rumor
  
  set run-res run-test-chance-of-abstention 500
  
  let many item 0 run-res
  let few item 4 run-res
  
;  print (word 
;    "strength:" strength-of-rumor " %-many:"polulation-%-little-sharers" %-few:"polulation-%-great-sharers 
;    " alpha-hs:" weibull-alpha-great-sharers " alpha-ls:" weibull-alpha-little-sharers " beta:"weibull-beta 
;    " many:" many " few:" few " sum:" (many + few)
;  )
  update-plots  
end

to great-sharers-in-comparison-to-little-sharers-all-tests
  
  request-output-file
  if (not is-string? filename) [ error "File does not exist." ]

  write-csv filename (list "rumor's strength" "# many" "# few" "alpha hs" "alpha ls" "beta" "many who have heard" "few who have heard" "total who have heard")

  set strength-of-rumor 0.50
  while [strength-of-rumor <= 1] [
    
    set weibull-alpha-great-sharers 0.25
    while [weibull-alpha-great-sharers <= 1] [
      
      let %-step 10
      while [%-step <= 90] [
        
        set polulation-%-little-sharers (100 - %-step)
        set polulation-%-great-sharers %-step
        
        great-sharers-in-comparison-to-little-sharers
        
        let many item 0 run-res
        let few item 4 run-res  
  
        write-csv filename (list 
          strength-of-rumor                     ; "rumor's strength"
          (item 0 count-turtles-grouped-by-age) ; "# many"
          (item 4 count-turtles-grouped-by-age) ; "# few" 
          weibull-alpha-great-sharers weibull-alpha-little-sharers weibull-beta            ; "alpha" "beta" 
          many few (many + few)                 ; "many who have heard" "few who have heard" "total who have heard"
        )
        set %-step (%-step + 5)
      ]
      set weibull-alpha-great-sharers (weibull-alpha-great-sharers + 0.25)
    ]    
    set strength-of-rumor (strength-of-rumor + 0.1)
  ]
  file-close
end

to great-sharers-in-comparison-to-little-sharers-all-tests-2
  
  request-output-file
  if (not is-string? filename) [ error "File does not exist." ]

  write-csv filename (list "rumor's strength" "# great sharers" "# little sharers" "alpha LS" "tot - alpha GS: 0.25" "tot - alpha GS: 0.50" "tot - alpha GS: 0.75" "tot - alpha GS: 1.0")

  
  foreach [0.50 0.60 0.70 0.75 0.80 0.90] [
  
    set strength-of-rumor ?
    
    let %-step 10
    while [%-step <= 90] [
      
      set polulation-%-little-sharers (100 - %-step)
      set polulation-%-great-sharers %-step
      
      let csv-line (list 
        strength-of-rumor                     ; "rumor's strength"
        ((num-nodes / 100) * polulation-%-great-sharers)  ; "# great sharers"
        ((num-nodes / 100) * polulation-%-little-sharers) ; "# little sharers"
        weibull-alpha-little-sharers
      )
      
      foreach [0.25 0.50 0.75 1.0] [
      
        set weibull-alpha-great-sharers ?
        
        great-sharers-in-comparison-to-little-sharers
        
        set csv-line lput (sum run-res) csv-line
      ]
      print csv-line
      write-csv filename csv-line
      set %-step (%-step + 5)
    ]
  ]
  file-close
end



; ######################################################################
; ######################################################################
;            File output functions: choose file and write csv           
; ######################################################################
; ######################################################################

to request-output-file 
  set-current-directory "/workspace/NetLogo/"
  
  set filename user-new-file
  print filename
  ;; We check to make sure we actually got a string just in case
  ;; the user hits the cancel button.
  if is-string? filename
  [
    ;; If the file already exists, we begin by deleting it, otherwise
    ;; new data would be appended to the old contents.
    if file-exists? filename
      [ file-delete filename ]
    file-open filename
  ]
end

; Thanks to James Steiner's answer
; https://groups.yahoo.com/neo/groups/netlogo-users/conversations/topics/17744
to write-csv [ #filename #items ]
  ;; #items is a list of the data (or headers!) to write.
  if is-list? #items and not empty? #items [ 
    file-open #filename
    ;; quote non-numeric items
    set #items map quote #items
    ;; print the items
    ;; if only one item, print it.
    ifelse (length #items = 1) [ 
      file-print first #items 
    ] [
      file-print reduce [ (word ?1 "," ?2) ] #items
    ]
    ;; close-up
    file-close
  ]
end

to-report quote [ #thing ]
  ifelse is-number? #thing [ 
    report (precision #thing 3)
  ][ 
    report (word "\"" #thing "\"") 
  ]
end



; ######################################################################
; ######################################################################
;            GUI Utilities: Layout and mouse relocate vertex
; ######################################################################
; ######################################################################

to my-layout-spring
  layout-spring turtles links spring-constant ((world-width - 2) / (sqrt num-nodes)) repulsion-constant
  ;layout-circle turtles 90
end
to my-layout-radial
  if (highest-degree-node != 0) [ ; every global variables are initialized with 0
    layout-radial turtles links highest-degree-node
  ]
end

; Thanks Jiri Lukas from: http://ccl.northwestern.edu/netlogo/models/community/Graph_search-DFS_and_BFS
to relocate-vertex
  if not any? turtles [
    user-message "There are no nodes"
    stop
    ]
  if mouse-down? [
    let candidate min-one-of turtles [distancexy mouse-xcor mouse-ycor]
    if [distancexy mouse-xcor mouse-ycor] of candidate < 2 [
      watch candidate
      while [mouse-down?] [
        display
        ask subject [ setxy mouse-xcor mouse-ycor ]
      ]
      reset-perspective
    ]
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
181
10
861
557
130
100
2.57
1
12
1
1
1
0
0
0
1
-130
130
-100
100
0
0
1
ticks
30.0

BUTTON
2
57
175
90
Create New Graph
create-new-graph
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
874
26
1035
59
LayoutSpring
my-layout-spring
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
2
23
175
56
num-nodes
num-nodes
100
5000
500
100
1
NIL
HORIZONTAL

SLIDER
874
257
1035
290
min-node-size
min-node-size
1
15
2
.5
1
NIL
HORIZONTAL

TEXTBOX
875
10
991
28
Some GUI utilities:
12
0.0
1

CHOOSER
2
214
175
259
social-network-type
social-network-type
"facebook" "twitter" "googleplus" "custom Social Network"
3

SLIDER
874
59
1035
92
repulsion-constant
repulsion-constant
0
50
1
1
1
NIL
HORIZONTAL

SLIDER
874
92
1035
125
spring-constant
spring-constant
0
1
0.23
0.01
1
NIL
HORIZONTAL

BUTTON
2
813
87
846
NIL
go
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
88
813
173
846
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

BUTTON
874
223
1035
256
Relocate Node
relocate-vertex
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
5
10
155
28
1) Choose how many nodes
10
0.0
1

TEXTBOX
3
201
181
227
2) Select one of the following social 
10
0.0
1

BUTTON
2
487
174
520
Setup Age distribution
setup-age-distribution
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
2
550
174
583
Setup Social Network
setup-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
2
462
168
488
3) Calculate and set the age distribution
10
0.0
1

TEXTBOX
1
524
172
550
4) Draw & setup all internal variables of the turtles
10
0.0
1

TEXTBOX
1
786
183
812
5) Single run: spread the rumor & reset
10
0.0
1

TEXTBOX
2
588
173
613
5) Set the spreading probabilities of \"rumor\" for each ages 
10
0.0
1

SLIDER
2
614
174
647
p-16-24
p-16-24
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
2
647
174
680
p-25-34
p-25-34
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
2
680
174
713
p-35-44
p-35-44
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
2
713
174
746
p-45-54
p-45-54
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
2
746
174
779
p-55-64
p-55-64
0
1
1
0.05
1
NIL
HORIZONTAL

BUTTON
2
847
173
880
Reset Last Run
reset-last-run
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
181
559
1086
916
Spread in a single run
ticks
Social Network Users
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Spreaders" 1.0 0 -14439633 true "" "plot count turtles with [shared?]"
"Uninterested" 1.0 0 -1184463 true "" "plot count turtles with [not shared? and seen?]"
"Ignorants" 1.0 0 -9276814 true "" "plot count turtles with [not seen?]"

TEXTBOX
15
276
165
294
NIL
12
0.0
1

TEXTBOX
3
264
179
303
Use the following sliders if you want to create a custom Social Network
10
0.0
1

SLIDER
2
289
175
322
%-16-24
%-16-24
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
2
322
175
355
%-25-34
%-25-34
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
2
355
175
388
%-35-44
%-35-44
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
2
388
175
421
%-45-54
%-45-54
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
2
421
175
454
%-55-64
%-55-64
0
100
0
1
1
NIL
HORIZONTAL

BUTTON
2
1124
251
1157
100 TEST - ONE AGE GROUP
average-100-only-p-16-24
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
255
919
1086
1416
Average 100 Tests
ticks
Average 100 Run
0.0
10.0
0.0
10.0
true
true
"if (is-list?  count-turtles-grouped-by-age) [\n  set-plot-y-range 0 ((max count-turtles-grouped-by-age) + 10)\n]" ""
PENS
"age 16-24" 1.0 0 -2674135 true "" "plot item 0 run-res"
"age 25-34" 1.0 0 -955883 true "" "plot item 1 run-res"
"age 35-44" 1.0 0 -1184463 true "" "plot item 2 run-res"
"age 45-54" 1.0 0 -10899396 true "" "plot item 3 run-res"
"age 55-64" 1.0 0 -13345367 true "" "plot item 4 run-res"
"max 16-24" 1.0 0 -1069655 true "" "plot item 0 count-turtles-grouped-by-age"
"max 25-34" 1.0 0 -408670 true "" "plot item 1 count-turtles-grouped-by-age"
"max 35-44" 1.0 0 -526419 true "" "plot item 2 count-turtles-grouped-by-age"
"max 45-54" 1.0 0 -4399183 true "" "plot item 3 count-turtles-grouped-by-age"
"max 55-64" 1.0 0 -5516827 true "" "plot item 4 count-turtles-grouped-by-age"

TEXTBOX
5
91
162
117
Or select one of the following pre created GraphML files
10
0.0
1

CHOOSER
2
117
175
162
graphml-file
graphml-file
"GS_10.xml" "GS_100.xml" "GS_300.xml" "GS_500.xml" "GS_5000.xml"
1

BUTTON
2
164
175
197
Import GraphML File
import-graphml-file
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
874
159
1035
192
Layout Radial
my-layout-radial
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
2
1190
251
1223
100 TEST - ALL AGE GROUPS DIAGONAL
average-100-p-16-to-64-diagonal
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
2
1157
251
1190
100 TEST - TWO AGE GROUPS
average-100-p-16-24-and-25-34
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1
1075
245
1093
6) Run average 
10
0.0
1

SWITCH
2
1091
251
1124
shuffle-ages-each-run
shuffle-ages-each-run
0
1
-1000

BUTTON
2
1621
259
1654
Great Sharers vs. Little Sharers
great-sharers-in-comparison-to-little-sharers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
3
1241
251
1384
7) Great sharers in comparison with a little sharers.\nIn order to do this test you have to set 'weibull-alpha-great-sharers', 'weibull-alpha-little-sharers' and 'weibull-beta'. After doing that you will obtain a modified curve of Weibull probability density function for both groups.\nYou also have to set the percentage of users for each group and the rumor's strength.\nLastly you will have to press the last button to launch the test, which will print in \"Command Center\" the average of 100 runs. 
10
0.0
1

SLIDER
2
1390
251
1423
weibull-alpha-little-sharers
weibull-alpha-little-sharers
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
2
1456
251
1489
weibull-beta
weibull-beta
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
2
1522
251
1555
polulation-%-little-sharers
polulation-%-little-sharers
0
100
10
5
1
NIL
HORIZONTAL

SLIDER
2
1555
251
1588
polulation-%-great-sharers
polulation-%-great-sharers
0
100
90
5
1
NIL
HORIZONTAL

PLOT
255
1418
670
1655
Great Sharers Probability Density Function
X
Prob. Density
0.0
10.0
0.0
10.0
true
false
"clear-plot\nset-plot-pen-mode 1\nset-plot-pen-interval 0.01\nset-plot-x-range 0 1\nupdate-plots" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram weibull-values"

PLOT
671
1418
1086
1655
Little Sharers Probability Density Function
X
Prob. Density
0.0
10.0
0.0
10.0
true
false
"clear-plot\nset-plot-pen-mode 1\nset-plot-pen-interval 0.01\nset-plot-x-range 0 1\nupdate-plots" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram one-minus-weibull-values"

BUTTON
2
1489
251
1522
Calculate Prob. Density with α and β
calc-weibull\nsetup-plots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
2
1588
251
1621
strength-of-rumor
strength-of-rumor
0
1
0.9
0.05
1
NIL
HORIZONTAL

SLIDER
2
1423
251
1456
weibull-alpha-great-sharers
weibull-alpha-great-sharers
0
1
0.25
0.05
1
NIL
HORIZONTAL

MONITOR
889
518
975
559
Spreaders
count turtles with [shared?]
0
1
10

MONITOR
975
518
1061
559
Uninterested
count turtles with [not shared? and seen?]
0
1
10

MONITOR
889
477
976
518
Ignorants
count turtles with [not seen?]
0
1
10

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

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

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

facebook
true
0
Circle -13345367 true false 1 0 300
Rectangle -7500403 true true 45 65 140 94
Rectangle -7500403 true true 60 142 128 173
Rectangle -7500403 true true 150 65 176 240
Rectangle -7500403 true true 165 65 246 90
Rectangle -7500403 true true 230 75 258 149
Rectangle -7500403 true true 165 214 241 240
Rectangle -13345367 true false 165 165 225 165
Rectangle -7500403 true true 166 143 245 171
Rectangle -7500403 true true 230 167 259 228
Rectangle -7500403 true true 45 75 76 240

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

googleplus
true
0
Circle -2674135 true false -7 -7 313
Rectangle -7500403 true true 225 105 240 210
Rectangle -7500403 true true 180 150 285 165
Circle -7500403 true true 15 121 150
Circle -2674135 true false 36 141 108
Rectangle -7500403 true true 150 60 165 195
Circle -7500403 true true 15 45 150
Circle -2674135 true false 36 66 108
Polygon -2674135 true false 15 150 45 180 45 210 15 210 15 150
Polygon -2674135 true false 0 120 60 210 0 180 0 120
Polygon -2674135 true false 127 196 144 171 144 196 127 195

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

television
false
14
Rectangle -16777216 true true 30 45 270 255
Rectangle -1 true false 63 78 243 228
Circle -16777216 true true 95 130 22
Polygon -16777216 true true 103 145 103 159 88 149 82 138 78 142 85 155 103 165 103 181 83 210 91 212 104 189 108 189 118 210 124 207 110 179 110 165 127 155 133 140 128 140 122 151 110 158 109 144
Polygon -16777216 true true 181 140 181 154 166 144 160 133 156 137 163 150 181 160 181 176 161 205 167 206 182 184 186 184 200 208 204 206 188 176 188 160 200 167 208 177 210 171 201 162 188 153 187 139
Circle -16777216 true true 173 126 22

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

twitter
true
0
Circle -13791810 true false 0 0 300
Rectangle -7500403 true true 30 90 135 105
Rectangle -7500403 true true 75 105 90 225
Polygon -7500403 true true 165 90 180 210 195 210 180 90 165 90
Polygon -7500403 true true 180 210 210 90 225 90 195 210 180 210
Polygon -7500403 true true 210 90 240 210 255 210 225 90 210 90
Polygon -7500403 true true 240 210 255 90 270 90 255 210 240 210

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
NetLogo 5.1.0
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
