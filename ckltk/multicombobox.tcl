package provide ckl::multicombobox 1.0

namespace eval ttk::multicombobox {
  variable Current
  variable Config
  set Config() {
    -listvariable {listVariable Variable {} {}}
  }
	variable scrollbar ttk::scrollbar
  if { [tk windowingsystem] eq "aqua" } {
		set scrollbar ::scrollbar
  }
}

proc ::ttk::multicombobox { w args } {
  set iargs [list]
  set margs [list]
  foreach {opt val} $args {
    switch -- $opt {
      -listvariable { lappend margs $opt $val }
      default       { lappend iargs $opt $val }
    }
  }
  eval combobox $w $iargs -class TMultiCombobox
  if { [$w cget -state] eq "normal" } {
    $w configure -state readonly
  }
  interp hide {} $w
  interp alias {} $w {} ::ttk::multicombobox::cmd $w
  set ::ttk::multicombobox::Current($w) [list]
  set ::ttk::multicombobox::Config($w) $::ttk::multicombobox::Config()
  foreach {opt val} $margs {
    $w configure $opt $val
  }
  return $w
}

ttk::copyBindings TCombobox TMultiCombobox

bind TMultiCombobox <KeyPress-Down>   { ttk::multicombobox::Post %W }
bind TMultiCombobox <ButtonPress-1> 		{ ttk::multicombobox::Press "" %W %x %y }
bind TMultiCombobox <Shift-ButtonPress-1>	{ ttk::multicombobox::Press "s" %W %x %y }
bind TMultiCombobox <Double-ButtonPress-1> 	{ ttk::multicombobox::Press "2" %W %x %y }
bind TMultiCombobox <Triple-ButtonPress-1> 	{ ttk::multlcombobox::Press "3" %W %x %y }

bind MultiComboboxListbox <ButtonRelease-1>	{ 
  if { [%W identify column %x %y] eq "#0" } {
	  ttk::multicombobox::LBSelect %W 
	} {
	  ttk::multicombobox::LBSelected %W 
	}
}
bind MultiComboboxListbox <KeyPress-Return>	{ ttk::multicombobox::LBSelected %W }
bind MultiComboboxListbox <KeyPress-space>	{ ttk::multicombobox::LBSelect %W }
bind MultiComboboxListbox <KeyPress-Escape> { ttk::combobox::LBCancel %W }
bind MultiComboboxListbox <KeyPress-Tab>	{ ttk::combobox::LBTab %W next }
bind MultiComboboxListbox <<PrevWindow>>	{ ttk::combobox::LBTab %W prev }
bind MultiComboboxListbox <Destroy>		{ ttk::combobox::LBCleanup %W }
bind MultiComboboxListbox <Motion>		{ ttk::multicombobox::LBHover %W %x %y }
bind MultiComboboxListbox <Map>				{ focus -force %W }

switch -- [tk windowingsystem] {
	win32 {
		# Dismiss listbox when user switches to a different application.
		# NB: *only* do this on Windows (see #1814778)
		bind MultiComboboxListbox <FocusOut>		{ ttk::combobox::LBCancel %W }
  }
}

proc ::ttk::multicombobox::cmd { self cmd args } {
  puts "$self -> $cmd -> $args"
  switch -- $cmd {
    current {
      tailcall cmd_current $self {*}$args
    }
    configure {
      tailcall cmd_configure $self {*}$args
    }
    set {
      error "command disabled: \"$self set ...\""
    }
    default { 
      tailcall interp invokehidden {} $self $cmd {*}$args 
    }
  }
}

proc ::ttk::multicombobox::cmd_current { self args } {
  variable Current
  if { [llength $args] > 1 } {
	  error "wrong # args: should be \"$self current ?list?\""
  } elseif { [llength $args] } {
    set Current($self) [lindex $args 0]
    set current [list]
    set itemidx -1
    foreach item [$self cget -values] {
      if { [lsearch $Current($self) [incr itemidx]] != -1 } { lappend current $item }
    }
    interp invokehidden {} $self set [join $current {, }]
    tracectl $self update
  }
  return $Current($self)
}

proc ::ttk::multicombobox::cmd_configure { self args } {
  variable Config
  switch [llength $args] {
    0 {
      set result [interp invokehidden {} $self configure]
      dict for {opt val} $Config($self) { lappend result [list $opt {*}$val] }
      return $result
    }
    1 {
      switch -- [lindex $args 0] {
        -listvariable {
          return [dict get $Config($self) -listvariable]
        }
        default {
		      tailcall interp invokehidden {} $self configure {*}$args
        }
      }
    }
    default {
      foreach {opt val} $args {
        switch -- $opt {
          -state {
            if { $val eq "normal" } { set val "readonly" }
          }
          -listvariable {
            tracectl $self remove
            if { $val ne "" } { set val "::$val" }
            dict set Config($self) -listvariable [lreplace [dict get $Config($self) -listvariable] end end $val]
            tracectl $self add
            continue  
          }
        }
        interp invokehidden {} $self configure $opt $val
      }
    }
  }
}

proc ::ttk::multicombobox::tracectl { self type } {
  variable Config
  if { $type eq "update" } {
    tracectl $self remove
    tracectl $self add
    return
  }
  if { [set var [lindex [dict get $Config($self) -listvariable] end]] ne "" } {
    if { $type eq "add" } {
      set $var [$self current]
    }
    trace $type variable $var {write unset} [namespace code [list trace_var $self]]
  }
}

proc ::ttk::multicombobox::trace_var { self varname aidx op } {
  upvar #0 $varname var
  if { $aidx eq "" } {
    set val $var
  } {
    set val [set var($aidx)]
    set varname "$varname\($aidx\)" 
  }
  if { $op eq "write" } {
    $self current $val  
  } {
    tracectl $self update
  }
}

proc ::ttk::multicombobox::cmd_cget { self args } {
  variable Config
  switch -- [lindex $args 0] {
    -listvariable {
      return [lindex [dict get $Config($self) -listvariable] end]
    }
    default {
		  tailcall interp invokehidden {} $self cget {*}$args
    }
  }
}

proc ttk::multicombobox::PopdownWindow {cb} {
	variable scrollbar

  if { ![winfo exists $cb.popdown] } {
		set poplevel [::ttk::combobox::PopdownToplevel $cb.popdown]
		set popdown [ttk::frame $poplevel.f -style ComboboxPopdownFrame]

		$scrollbar $popdown.sb \
		    -orient vertical -command [list $popdown.l yview]
		::ttk::treeview $popdown.l -columns {1} \
		  -yscrollcommand [list $popdown.sb set] \
		  -show {tree} \
		  -selectmode browse

		$popdown.l column \#0 -width 38 -stretch 0
		$popdown.l column 1 -width 10 -stretch 1

   	bindtags $popdown.l \
	    [list $popdown.l MultiComboboxListbox Treeview $popdown all]

		grid $popdown.l -row 0 -column 0 -padx {1 0} -pady 1 -sticky nsew
    grid $popdown.sb -row 0 -column 1 -padx {0 1} -pady 1 -sticky ns
		grid columnconfigure $popdown 0 -weight 1
		grid rowconfigure $popdown 0 -weight 1
    grid $popdown -sticky news -padx 0 -pady 0
    grid rowconfigure $poplevel 0 -weight 1
    grid columnconfigure $poplevel 0 -weight 1
  }
  return $cb.popdown
}

proc ttk::multicombobox::ConfigureListbox {cb} {
  set popdown [PopdownWindow $cb].f
  set values [$cb cget -values]
  set current [$cb current]
  set ::ttk::Values($cb) $values
  $popdown.l delete [$popdown.l children {}]
  if { [llength $values] } {
	  set itemidx -1
	  foreach val $values {
	    $popdown.l insert {} end \
	      -image ::ttk::multicombobox::img[expr { [lsearch $current [incr itemidx]] != -1 }] \
	      -values [list $val]
	  }
	  set childs [$popdown.l children {}]
	  if { [llength $current] } {
	    set current [lindex $childs [lindex $current 0]]
	  } {
	    set current [lindex $childs 0]
	  }
	  $popdown.l selection set $current
	  $popdown.l focus $current
	  $popdown.l see $current
	}
  set height [llength $values]
  if { $height > [$cb cget -height] } {
		set height [$cb cget -height]
    grid $popdown.sb
    grid configure $popdown.l -padx {1 0}
  } else {
		grid remove $popdown.sb
    grid configure $popdown.l -padx 1
  }
  $popdown.l configure -height $height
}

proc ttk::multicombobox::Post { cb } {
  $cb instate disabled { return }
  uplevel #0 [$cb cget -postcommand]
  set popdown [PopdownWindow $cb]
  ConfigureListbox $cb
  update idletasks	;# needed for geometry propagation.
  ::ttk::combobox::PlacePopdown $cb $popdown
  switch -- [tk windowingsystem] {
		x11 - win32 { wm transient $popdown [winfo toplevel $cb] }
  }
  wm attribute $popdown -topmost 1
  wm deiconify $popdown
  raise $popdown
}

proc ttk::multicombobox::Press {mode w x y} {
	$w instate disabled { return }
  set ::ttk::combobox::State(entryPress) [expr {
	  [$w instate !readonly]
		&& [string match *textarea [$w identify element $x $y]]
  }]
  focus $w
  if { $::ttk::combobox::State(entryPress) } {
		switch -- $mode {
	    s { ttk::entry::Shift-Press $w $x 	; # Shift }
	    2	{ ttk::entry::Select $w $x word 	; # Double click}
	    3	{ ttk::entry::Select $w $x line 	; # Triple click }
	    ""	-
	    default { ttk::entry::Press $w $x }
		}
  } else {
		Post $w
  }
}

proc ttk::multicombobox::LBSelected { lb } {
	set cb [::ttk::combobox::LBMaster $lb]
  LBSelect $lb 1
  ::ttk::combobox::Unpost $cb
  focus $cb
}

proc ttk::multicombobox::LBHover { w x y } {
  if { [set item [$w identify item $x $y]] ne "" } {
    $w selection set $item
    $w focus $item
  }
}

proc ttk::multicombobox::LBSelect { lb {one 0} } {
	set cb [::ttk::combobox::LBMaster $lb]
  set selection [$lb index [lindex [$lb selection] 0]]
  if { $one } {
    set current [$cb current $selection]
  } {
    set current [$cb current]
    if { [set pos [lsearch $current $selection]] == -1 } {
      lappend current $selection
    } {
      set current [lreplace $current $pos $pos]
    }
    $cb current $current
  }
  # TODO
  # можно оптимизировать, не изменяя картинки у всех, а только у тех, что действительно нужно менять
  set itemidx -1
  foreach item [$lb children {}] {
    $lb item $item -image ::ttk::multicombobox::img[expr { [lsearch $current [incr itemidx]] != -1 }]
  }
  event generate $cb <<ComboboxSelected>> -when mark
}

image create photo ::ttk::multicombobox::img0 -data {
    R0lGODlhDwAPANUAANnZ2Y6Pj/T09K6zua+0urS5vbu+wcvP1dDT2NXY3Nvd38HDxc3R1tLV2tjb
    3t3f4eLj5MbHyM3R19DU2dTX2+Hi4+Xm5ujo6MzNzbK3vNrc3+Dh4+zs7O3t7dTV1ri7v+Tl5erq
    6u/v7/Ly8tzd3ry/wuPk5enp6fX19eHi4sLExvDw8Pb29ubm5srLzNTU1dvb3ODh4ebn5+rr6+vs
    7Ovr7Onp6v///////////////////////////////////yH5BAEAAAAALAAAAAAPAA8AAAZvQIBw
    SCwCAsikMikMCJ7QqCDQFAyuWELBMK0ODuADIqFYdI9WMKPheEAiZ+dAMqEoKpYLJi7IJDQbFxwd
    HR58Hw8gISIjjSR8JSYnHSMCKAIpfCqTKwIsny18Li8wMTIzNDU2fFJSVEdLsa9GtABBADs=}
image create photo ::ttk::multicombobox::img1 -data {
    R0lGODlhDwAPAOYAANnZ2Y6Pj/T09Pj4+Pn5+fb29q6zucnM0J2nwHeGq9zf5PX19cvP1czQ1u3u
    8VdqnURakrm/0M3R1uDi5q+4z0VakmV3pefn6NXZ3d/i5dXY3PLz9F5xoUdclLzD1tvc3MXJzcnP
    3aOuyO3u7rrB1UlelmR2pdXV1t7g4W5/qs/U4md4p0tgl7e/1dzd3s3P0d7h6UhdlUlflmFzpPj5
    +uHi4sbIyurs8IuZu0pfl0xhmLC50ebm5srLzNra29/i6YyZupCdvfLz9uzt7evr7Onp6v//////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////yH5
    BAEAAAAALAAAAAAPAA8AAAeFgACCg4SFAAGIiYqJggECj5ACAwQFAgGNAgaamgcICQoLl4eZDKUN
    Dg8QEQWijgalEhMUFRYXlpgGGBkaGxwdHh+3oyAhIiMkJSYDJ8KOKCkdKissLQUuzQIvMDEyLDM0
    AjXYNjc4OTo7lDzYPT4/QEFCQ0RF2I8LBAMLka2L/qKGAgIIBAA7}
