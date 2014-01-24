package require Tcl 8.6
package require msgcat

package provide ckl::dateentry 1.0

namespace eval ::ckl::dateentry {
  namespace export widget

  variable img_button [image create photo -data {
iVBORw0KGgoAAAANSUhEUgAAAA4AAAANCAIAAAAWvsgoAAAABGdBTUEAAK/INwWK6QAAABl0RVh0
U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGkSURBVHjadFHNahRBEK7q6Z3Jzq6ih/gL
xoMbMHENufgKQfBxfAsPvoBv4MGDFxEU9SSYSyBZlEQSERWzsCbZmemZrq5qq1eP+kEX3V1VX318
hW8mlSfpl31CKxIlggYWjZH1rg/h9mT2Zers9xlt3BquZZ/g5xFgBjHlIQowgzBoU9E/uXf/0bMD
G1g6Y2HvFRy+hfIcBAL2KfoWvAPnoLLVwwdEYjmNBIgIGST0DMQMljDRFxZMpqx6pRAss4hrYW1r
199YWR4eHjerV8vJ12q8Ptg5mm9uDvamdN63iZVYAnVwafXzlZXlUbEPzc075ce2uX23nDT1eGMw
+XA6bpwPwahWlaDIQ2085dxgxznX6KXgGkiknbuO1SWTBPypRfgnOkp5FjaeFRH+A034EDPEssiS
AF6wIoLVP4TeIubWGMSiZwLxoimqr6HIcfvg7Mese7kzaz0/fT+tHD15/e20ocfP6yx5CUaJ1AHX
hfFocPmCtkWVnuZwoZOUW9fbM2bekm7cXr+49G7314vtYx/YBy1i4hh0W3+BixNH14a/BRgABW4a
qVXTZAoAAAAASUVORK5CYII=}]
  variable img_prev [image create photo -data {
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAJCAYAAAARml2dAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJ
bWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdp
bj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6
eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEz
NDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJo
dHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlw
dGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAv
IiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RS
ZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpD
cmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNl
SUQ9InhtcC5paWQ6QzNGOThFOEI4MjczMTFFMEE2MUVFNDA2Mjg4Q0Q0OTciIHhtcE1NOkRvY3Vt
ZW50SUQ9InhtcC5kaWQ6QzNGOThFOEM4MjczMTFFMEE2MUVFNDA2Mjg4Q0Q0OTciPiA8eG1wTU06
RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDM0Y5OEU4OTgyNzMxMUUwQTYx
RUU0MDYyODhDRDQ5NyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDM0Y5OEU4QTgyNzMxMUUw
QTYxRUU0MDYyODhDRDQ5NyIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1w
bWV0YT4gPD94cGFja2V0IGVuZD0iciI/PjpXfykAAACGSURBVHjaYvj//z8DOo5OyZRmYUACMalZ
nECqiJGRsZIFSTAQKDARqEMWpIsFKGAAFJ8AxPYgARhgYWZi2vf33z9BBjTAfOzQwZI/f/9yPXj0
mOHfv39wCUagdn4gXffi1avcRctXsV66cg0ig+RMFSDefvHy1f9ldU2YfgBiD6DRVwECDABKmF/L
08LBvQAAAABJRU5ErkJggg==}]
  variable img_next [image create photo -data {
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAJCAYAAAARml2dAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJ
bWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdp
bj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6
eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEz
NDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJo
dHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlw
dGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAv
IiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RS
ZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpD
cmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNl
SUQ9InhtcC5paWQ6QzNGOThFOEY4MjczMTFFMEE2MUVFNDA2Mjg4Q0Q0OTciIHhtcE1NOkRvY3Vt
ZW50SUQ9InhtcC5kaWQ6QzNGOThFOTA4MjczMTFFMEE2MUVFNDA2Mjg4Q0Q0OTciPiA8eG1wTU06
RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDM0Y5OEU4RDgyNzMxMUUwQTYx
RUU0MDYyODhDRDQ5NyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDM0Y5OEU4RTgyNzMxMUUw
QTYxRUU0MDYyODhDRDQ5NyIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1w
bWV0YT4gPD94cGFja2V0IGVuZD0iciI/PstIyfUAAAB9SURBVHjaYohOyZT+//8/AzpmYmRkvBmT
mlUNxJwMSIAJKMsNpFugCgJhEoxAo/4zoIKDQFzAxIAJ7JmYmA6wIIuwsLAwuDraMwT6eP2DS+jp
aDHERYb9lhATmwzkNjGU1TX9v3j5KtAN/7cDsQrMuQx//v4FiXqg+wMgwADSSEqWpVMGCAAAAABJ
RU5ErkJggg==}]  

  variable cfg {
    month {
      bg      #d6dcee
      font    {Helvetica 10 bold}
    }
    year {
      bg      #d6dcee
      font    {Helvetica 10 bold}
    }
    qbutton {
      default {
        bg   #ffffff
        font {Helvetica 9}
      }
      hover {
        bg   #d6dcee
      }
    }
    days {
      default {
        bg   #ffffff
        fg   #07074c
        font {Helvetica 9 bold}
        bd   {-bd 1 -relief flat}
      }
      sunday {
        bg   #ffffff
        fg   #cc0000
      }
      saturday {
        bg   #ffffff
        fg   #cc0000
      }
      hover {
        bg   #eeeeee
        bd   {-bd 1 -relief solid}
      }
      today {
        bg   #d6dcee
        font {Helvetica 9 bold}
      }
    }
    inactive {
      default {
        bg   #eeeeee
        fg   #999999
        font {Helvetica 8}
        bd   {-bd 1 -relief flat}
      }
      sunday {
        bg   #eeeeee
        fg   #cc9999
      }
      saturday {
        bg   #eeeeee
        fg   #cc9999
      }
    }
    week_header {
      default {
        bg   #3e3ea8
        fg   #ffffff
        font {Helvetica 9 bold}
      }
      sunday {
        bg   #a84e4e
        fg   #ffffff
      }
      saturday {
        bg   #a84e4e
        fg   #ffffff
      }
    }
    defaults {
      sunday_first 0
      locale current
      format "%d.%m.%Y"
      date 0
      qbuttons_format %d.%m.%Y
      qbuttons_jump 0
      qbuttons {
        0 {
          title "Today"
          date "now"
          place bottom
          showdate 1
        }
        1 {
          title "Yesterday"
          date "yesterday"
          place bottom
        }
        2 {
          title "Beginning of current week"
          date "start of week now"
          place right
        }
        3 {
          title "End of current week"
          date "end of week now"
          place right
        }
        4 {
          title "Beginning of previous week"
          date "start of week now -1 week"
          place right
        }
        5 {
          title "End of previous week"
          date "end of week now -1 week"
          place right
        }
        6 {
          title "Beginning of current month"
          date "start of month now"
          place right
        }
        7 {
          title "End of current month"
          date "end of month now"
          place right
        }
        8 {
          title "Beginning of previous month"
          date "start of month now -1 month"
          place right
        }
        9 {
          title "End of previous month"
          date "end of month now -1 month"
          place right
        }
        10 {
          title "Beginning of current year"
          date "start of year now"
          place right
        }
        11 {
          title "End of current year"
          date "end of year now"
          place right
        }
      }
    }
  }
  dict set cfg defaults today [clock format [clock seconds] -format %d%m%Y]
  dict set cfg defaults year_selection \
    [list [expr { [clock format [clock seconds] -format %Y] - 5 }] [expr { [clock format [clock seconds] -format %Y] + 5 }]]

  variable win ".dateentry_select"
  variable langdir [file join [file dirname [info script]] msgs]
}

bind DateEntryCalendar <Map>   { ttk::globalGrab %W  }
bind DateEntryCalendar <Unmap> { ttk::releaseGrab %W }
bind DateEntryCalendarPopup <Map>   { ttk::globalGrab %W  }
bind DateEntryCalendarPopup <Unmap> { ttk::releaseGrab %W }

proc ::ckl::dateentry::format { w } {
  variable cfg
  set ic [$w.entry index insert]
  $w.entry delete 0 end
  $w.entry insert end [clock format [dict get $cfg $w date] -format [dict get $cfg $w format]]
  $w.entry icursor $ic
}

proc ::ckl::dateentry::entryButtonClick { w x } {
  variable cfg
  $w.entry selection clear
  set pos [$w.entry index @$x]
  if { $pos <= [dict get $cfg $w eformat 0 start] } {
    $w.entry icursor [dict get $cfg $w eformat 0 start]
  } elseif { $pos >= [dict get $cfg $w eformat last end] } {
    $w.entry icursor [dict get $cfg $w eformat last end]
  } {
    dict for {id cfrm} [dict get $cfg $w eformat] {
      if { $pos >= [dict get $cfrm start] && $pos <= [dict get $cfrm end] } {
        break  
      } 
      set nfrm [dict get $cfg $w eformat [expr { $id + 1 }]]
      if { $pos > [dict get $cfrm end] && $pos < [dict get $nfrm start] } {
        if { ($x - [lindex [$w.entry bbox [dict get $cfrm end]] 0] - [lindex [$w.entry bbox [dict get $cfrm end]] 2]) < \
             ([lindex [$w.entry bbox [dict get $nfrm start]] 0] - $x) } {
          set pos [dict get $cfrm end]
        } {
          set pos [dict get $nfrm start]
        }
        break
      }
    }
    $w.entry icursor $pos
  }
  if { "disabled" ne [$w.entry cget -state] } {
		focus $w.entry
  }
  return -code break
}

proc ::ckl::dateentry::entryTracerseIn { w } {
  variable cfg
  $w.entry selection clear
  $w icursor [dict get $cfg $w eformat 0 start]
  return -code break
}

proc ::ckl::dateentry::entryPaste { w } {
  foreach c [split [::tk::GetSelection $w.entry CLIPBOARD] ""] {
    catch { entryKey $w $c "" "" 1 }
  }
  return -code break
}

proc ::ckl::dateentry::entryKey { w char sym state {nobell 0} } {
  variable cfg

  set e $w.entry
  set ic [$e index insert]
  # search current format where cursor in
  dict for {- cfrm} [dict get $cfg $w eformat] {
    if { $ic >= [dict get $cfrm start] && $ic <= [dict get $cfrm end] } break
  }

  if { $sym in {Left BackSpace} } {
    if { $ic == [dict get $cfrm start] } {
      if { [dict get $cfrm idx] } {
        $e icursor [dict get $cfg $w eformat [expr { [dict get $cfrm idx] - 1 }] end]
      } {
        bell
      }  
    } {
      incr ic -1
      if { $sym eq "BackSpace" } {
        $e delete $ic
        $e insert $ic 0
      }
      $e icursor $ic
    }
    return -code break
  } elseif { $sym eq "Right" } {
    if { $ic == [dict get $cfrm end] } {
      if { [dict exists $cfrm last] } {
        bell
      } {
        $e icursor [dict get $cfg $w eformat [expr { [dict get $cfrm idx] + 1 }] start]
      }
    } {
      $e icursor [incr ic]
    }
    return -code break
  } elseif { $sym eq "Delete" } {
    if { $ic != [dict get $cfrm end] } {
      $e delete $ic
      $e insert $ic 0
      $e icursor $ic
    }
    return -code break
  } elseif { $sym eq "Home" } {
    $e icursor [dict get $cfg $w eformat 0 start]
    return -code break
  } elseif { $sym eq "End" } {
    $e icursor [dict get $cfg $w eformat last end]
    return -code break
  } elseif { $sym eq "Tab" && ($state == 1 || $state == 4) } {
    if { [dict get $cfrm idx] } {
      $e icursor [dict get $cfg $w eformat [expr { [dict get $cfrm idx] - 1 }] start]
      return -code break
    } 
    return -code continue
  } elseif { $sym eq "Tab" && $state == 0 } {
    if { ![dict exists $cfrm last] } {
      $e icursor [dict get $cfg $w eformat [expr { [dict get $cfrm idx] + 1 }] start]
      return -code break
    } 
    return -code continue
  }

  # no char, continue
  if { $char eq "" } {
    return -code continue
  }

  # not digit
  if { ![string match {[0-9]} $char] } {
    if { !$nobell } {
	    bell
	  }
    return -code break
  }
  # check end of format
  if { $ic >= [dict get $cfrm end] } {
    # if last format - error
    if { [dict exists $cfrm last] } {
	    bell
  	  return -code break
  	}
  	# jump to next format
  	set cfrm [dict get $cfg $w eformat [expr { [dict get $cfrm idx] + 1 }]]
    $e icursor [dict get $cfrm start]
    set ic [dict get $cfrm start]
  }
  $e delete $ic
  $e insert $ic $char

  #if reach end of format
  if { [$e index insert] >= [dict get $cfrm end] } {
    # if format not last - jump to next format
    if { ![dict exists $cfrm last] } {
      $e icursor [dict get $cfg $w eformat [expr { [dict get $cfrm idx] + 1 }] start]
    }
    # if format is last - do nothing
  }

  entry2date $w [dict get $cfrm idx]

  return -code break
}

proc ::ckl::dateentry::entry2date { w incorrectidx } {
  variable cfg
  dict for {idx cfrm} [dict get $cfg $w eformat] {
    if { $incorrectidx eq "all" || $idx eq $incorrectidx } {
		  dict set cfg $w eformat $idx incorrect 1
    }
  }

  set e $w.entry

  # try to insert all 'incorrect' dates to current date
  lassign [split [clock format [dict get $cfg $w date] -format "%d-%m-%Y"] -] day month year
  dict for {- cfrm} [dict get $cfg $w eformat] {
    if { ![dict exists $cfrm incorrect] } continue
    switch -- [dict get $cfrm frm] {
      e - d { set var day   }
      m - N { set var month }
      y - Y     { set var year  }
      default { continue }
    }
    set val [string range [$e get] [dict get $cfrm start] [expr { [dict get $cfrm end] - 1 }]]
    if { $var eq "year" && [string length $val] } {
      set val [string trimleft $val {0 }]
      if { [string is integer -strict $year] } {
        if { $year >= 0 && $year <= 37 } {
          incr year 2000
        } elseif { $year >= 38 } {
          incr year 1900
        }
      }  
    } {
      set val [string trimleft $val {0 }]
    }
    set $var $val
  }
  if { [string is integer -strict $year] && $year >= 1900 && $year <= 2999 } {
    if { [string is integer -strict $month] && $month >= 1 && $month <= 12 } {
      if { [string is integer -strict $day] && $day >= 1 } {
        if { $day <= [string trimleft [clock format [clock scan "+1 month -1 day" \
  							        -base [clock scan "$month/01/$year"]] -format %d] 0] } {
			    dict set cfg $w date [clock scan "$month/$day/$year"]
			    tracectl update $w
			    # remove all 'incorrect' labels
			    dict for {id cfrm} [dict get $cfg $w eformat] {
			      if { ![dict exists $cfrm incorrect] } continue
			      dict unset cfg $w eformat $id incorrect
			    }
        }
      }
    }
  }
}

proc ::ckl::dateentry::parse_date { sunday_first d } {
  set anchor [set unit ""]
  if { [regexp {^(start|end)\s+(?:of\s+)?(year|month|week)\s+(.+)$} $d - anchor unit other] } {
    set d $other
  }
  set d [clock scan $d]
  switch -- "$anchor$unit" {
    startmonth {
      set d [clock scan [clock format $d -format {01/%m/%Y}] -format {%d/%m/%Y}]
    }
    endmonth {
      set d [clock scan {+1 month -1 day} -base [clock scan [clock format $d -format {01/%m/%Y}] -format {%d/%m/%Y}]]
    }
    startyear {
      set d [clock scan [clock format $d -format {01/01/%Y}]]
    }
    endyear {
      set d [clock scan {+1 year -1 day} -base [clock scan [clock format $d -format {01/01/%Y}]]]
    }
    startweek {
      while { [clock format $d -format %u] != [expr { $sunday_first ? 7 : 1 }] } {
        set d [clock scan {-1 day} -base $d]
      }
    }
    endweek {
      while { [clock format $d -format %u] != [expr { $sunday_first ? 6 : 7 }] } {
        set d [clock scan {+1 day} -base $d]
      }
    }
  }
  return $d
}

proc ::ckl::dateentry::tracectl { type w } {
  variable cfg
  if { $type eq "update" } {
    tracectl remove $w
	  tracectl add $w
	  return
  }
  if { [dict exists $cfg $w variable_integer] } {
    if { $type eq "add" } {
      set [dict get $cfg $w variable_integer] [dict get $cfg $w date]
    }
    trace $type variable [dict get $cfg $w variable_integer] {write unset} \
	    [namespace code [list trace_var $w integer]]
  }
  if { [dict exists $cfg $w variable_string] } {
    if { $type eq "add" } {
      set [dict get $cfg $w variable_string] [$w.entry get]
    }
    trace $type variable [dict get $cfg $w variable_string] {write unset} \
      [namespace code [list trace_var $w string]]
  }
}

proc ::ckl::dateentry::trace_var { w type varname aidx op } {
  variable cfg
  upvar #0 $varname var
  if { $aidx eq "" } {
	  set val $var
  } {
    set val [set var($aidx)]
    set varname "$varname\($aidx\)" 
  }


  set savestate [$w.entry cget -state]
  $w.entry configure -state normal
  if { $op eq "write" } {
    if { $type eq "integer" } {
      if { [string is integer -strict $val] } {
        dict set cfg $w date $val
        format $w
      }
    } {
      set saveic [$w.entry index insert]
      $w.entry delete 0 end
      $w.entry insert end $val
      $w.entry icursor $saveic
      entry2date $w all
    }
  }
  $w.entry configure -state $savestate

  tracectl update $w
}


proc ::ckl::dateentry::select_close { {value ""} } {
  variable win
  variable cur_widget
  variable cur_year
  variable cur_month
  variable cfg

  if {[winfo exists $win]} {
		wm withdraw $win
		destroy $win
  }
  grab release $win

  if { $value ne "" } {
    configure $cur_widget -date [clock scan "$cur_month/$value/$cur_year"]
    event generate $cur_widget.entry <KeyPress> -keysym End
  }
  unset cur_month cur_widget cur_year
}

proc ::ckl::dateentry::listbox_close { {returnvalue 0} } {
  variable win
  variable cur_month
  variable cur_year
  variable lb_type
  variable cur_widget

  if { $returnvalue } {
    if { $lb_type eq "month" } {
      set cur_month [expr { [lindex [$win.lb.main.lb curselection] 0] + 1 }]
    } {
      set cur_year [$win.lb.main.lb get [lindex [$win.lb.main.lb curselection] 0]]
    }
    update_view $cur_widget
  }

  if { [winfo exists $win.lb] } {
    wm withdraw $win.lb
    destroy $win.lb
  }
  grab release $win.lb

  unset lb_type
}

proc ::ckl::dateentry::listbox_open { w what } {
  variable win
  variable cfg
  variable cur_month
  variable cur_year
  variable lb_type
  
  if { [winfo exists $win.lb] } listbox_close
  set lb_type $what
  toplevel $win.lb -class DateEntryCalendarPopup
  wm withdraw $win.lb
  switch -- [tk windowingsystem] {
  	default -
		x11 {
	    $win.lb configure -relief flat -borderwidth 0
	    wm attributes $win.lb -type combo
	    wm overrideredirect $win.lb true
		}
		win32 {
	    $win.lb configure -relief flat -borderwidth 0
	    wm overrideredirect $win.lb true
	    wm attributes $win.lb -topmost 1
		}
		aqua {
	    $win.lb configure -relief solid -borderwidth 0
	    tk::unsupported::MacWindowStyle style $win.lb help {noActivates hideOnSuspend}
	    wm resizable $win.lb 0 0
		}
  }
	bind $win.lb <Escape> [namespace code listbox_close]
  bind $win.lb <ButtonPress> [namespace code {
    if { [string first %W [winfo containing %X %Y]] != 0 } listbox_close
  }]
  pack [frame $win.lb.main -borderwidth 1 -relief solid -takefocus 0]
  pack [listbox $win.lb.main.lb -exportselection false \
    -selectmode browse -activestyle none -relief flat \
    -font [dict get $cfg $w $what font]]
  if { $what eq "month" } {
    $win.lb.main.lb insert end {*}[dict get $cfg $w month_list]
    set current_item [expr { $cur_month - 1 }]
  } {
    for { set year [lindex [dict get $cfg $w year_selection] 0] } \
        { $year <= [lindex [dict get $cfg $w year_selection] 1] } { incr year } {
      $win.lb.main.lb insert end $year
      if { $year eq $cur_year } {
        set current_item [expr { [$win.lb.main.lb index end] - 1 }]
      }
    }
  }
  if { ![info exists current_item] } { set current_item 0 }
  $win.lb.main.lb configure -height [$win.lb.main.lb index end]
  $win.lb.main.lb selection clear 0 end
  $win.lb.main.lb selection set $current_item
  $win.lb.main.lb activate $current_item
  if { [dict exists $cfg $w days today bg] } {
    $win.lb.main.lb itemconfigure $current_item -background [dict get $cfg $w days today bg]
  }
  if { [dict exists $cfg $w days today fg] } {
    $win.lb.main.lb itemconfigure $current_item -foreground [dict get $cfg $w days today fg]
  }
  bind $win.lb.main.lb <ButtonRelease-1>	{ ckl::dateentry::listbox_close 1; break }
	bind $win.lb.main.lb <KeyPress-Return>	{ ckl::dateentry::listbox_close 1; break }
	bind $win.lb.main.lb <Motion>		{ 
    %W selection clear 0 end
    %W activate @%x,%y
    %W selection set @%x,%y
	}
	bind $win.lb.main.lb <Map>		{ focus -force %W }

  update idletasks
  set x [winfo rootx $win.main.header.[string index $what 0]_prev]
  incr x 2
  set y [winfo rooty $win.main.header.[string index $what 0]_prev]
  incr y [winfo height $win.main.header.[string index $what 0]_prev]
  set width [expr { [winfo rootx $win.main.header.[string index $what 0]_next] + \
                    [winfo width $win.main.header.[string index $what 0]_next] - $x - 4 }]
  set height [winfo reqheight $win.lb]
  wm geometry $win.lb "${width}x${height}+${x}+${y}"
  switch -- [tk windowingsystem] {
		x11 - win32 { wm transient $win.lb $win }
  }
  wm deiconify $win.lb
  raise $win.lb
}

proc ::ckl::dateentry::select_open { w } {
  variable cfg
  variable img_prev
  variable img_next
  variable cur_year
  variable cur_month
  variable cur_widget
  variable win

  if { [winfo exists $win] } select_close
  toplevel $win -class DateEntryCalendar
  wm withdraw $win
  switch -- [tk windowingsystem] {
  	default -
		x11 {
	    $win configure -relief flat -borderwidth 0
	    wm attributes $win -type combo
	    wm overrideredirect $win true
		}
		win32 {
	    $win configure -relief flat -borderwidth 0
	    wm overrideredirect $win true
	    wm attributes $win -topmost 1
		}
		aqua {
	    $win configure -relief solid -borderwidth 0
	    tk::unsupported::MacWindowStyle style $win help {noActivates hideOnSuspend}
	    wm resizable $win 0 0
		}
  }
  
  pack [frame $win.main -borderwidth 1 -relief solid -takefocus 0]
  grid [frame $win.main.header] -column 0 -row 0 -columnspan 7 -sticky nsew
  pack [button $win.main.header.m_prev -image $img_prev \
         -command [namespace code [list btn_cmd $w mon prev]] -relief flat -takefocus false] \
       [label $win.main.header.mon -text ""] \
       [button $win.main.header.m_next -image $img_next \
         -command [namespace code [list btn_cmd $w mon next]] -relief flat -takefocus false] \
       [button $win.main.header.y_prev -image $img_prev \
         -command [namespace code [list btn_cmd $w year prev]] -relief flat -takefocus false] \
       [label $win.main.header.year -text ""] \
       [button $win.main.header.y_next -image $img_next \
         -command [namespace code [list btn_cmd $w year next]] -relief flat -takefocus false] \
           -side left -fill both -expand 1

  set_color $w $win.main.header.m_prev {month}
  set_color $w $win.main.header.m_next {month}
  set_color $w $win.main.header.mon    {month}
  set_color $w $win.main.header.y_prev {year}
  set_color $w $win.main.header.y_next {year}
  set_color $w $win.main.header.year   {year}
  set maxwidth 0
  foreach _ [dict get $cfg $w month_list] { 
    if { $maxwidth < [string length $_] } { set maxwidth [string length $_] } 
  }

  $win.main.header.mon configure -width $maxwidth
  $win.main.header.year configure -width 4

  set tm [dict get $cfg $w day_list]
  if { ![dict get $cfg $w sunday_first] } {
    lappend tm [lindex $tm 0]
    set tm [lreplace $tm 0 0]
  }

  foreach _ {0 1 2 3 4 5 6} {
    ttk::label $win.main.week_day$_ -text [lindex $tm $_] -width 3 -justify center -anchor center
    set cmd [list set_color $w $win.main.week_day$_ {week_header default}]
    switch -- [dict get $cfg $w sunday_first]$_ {
      05 - 16 { lappend cmd {week_header saturday} }
      06 - 10 { lappend cmd {week_header sunday}   }
    }
    eval $cmd
    grid $win.main.week_day$_ -column $_ -row 1 -sticky nsew
  }

  lassign [clock format [dict get $cfg $w date] -format "%Y %m"] cur_year cur_month
  set cur_month [string trimleft $cur_month 0]

  set cur_widget $w

	bind $win <Escape> [namespace code select_close]
  bind $win <ButtonPress> [namespace code {
    if { [string first %W [winfo containing %X %Y]] != 0 } select_close
  }]
  bind $win.main.header.mon  <ButtonRelease> [namespace code [list listbox_open $w month]]
  bind $win.main.header.year <ButtonRelease> [namespace code [list listbox_open $w year]]
  update_view $w

  set config_button [list {w num args} {
    variable cfg
    foreach {L W} $args {
      bind $W <Any-Enter> [namespace code [list qbtn_cmd Enter $w $num]]
      bind $W <Any-Leave> [namespace code [list qbtn_cmd Leave $w $num]]
      bind $W <ButtonRelease> [namespace code [list qbtn_cmd Press $w $num]]
      set_color $w $W {qbutton default}
      dict set cfg $w qbuttons $num $L $W
    }
  } [::namespace current]]

  if { [dict exists $cfg $w qbuttons_bottom] } {
    set row 7
    dict for {num qb} [dict get $cfg $w qbuttons] {
      if { [dict get $qb place] ne "bottom" } continue
      grid [frame $win.main.buttons$num] -column 0 -row [incr row] -columnspan 7 -sticky nsew
      if { $row == 8 } {
        pack [ttk::separator $win.main.buttons$num.sep -orient horizontal] -expand 1 -fill x -side top
      }
      pack [label $win.main.buttons$num.bl -text [mc $w [dict get $qb title]] -anchor w] -side left -expand 1 -fill x
  	  apply $config_button $w $num Wlabel $win.main.buttons$num.bl
      if { [dict exists $qb showdate] && [dict get $qb showdate] } {
        pack [label $win.main.buttons$num.bw -text [dict get $qb date] -padx 3] -side right
        apply $config_button $w $num Wdate $win.main.buttons$num.bw
      }
    }
  }

  if { [dict exists $cfg $w qbuttons_right] } {
    grid [ttk::separator $win.main.sepv -orient vertical] -column 7 -row 0 -sticky nsew -rowspan [lindex [grid size $win.main] 1]
    set row -1
    dict for {num qb} [dict get $cfg $w qbuttons] {
      if { [dict get $qb place] ne "right" } continue
	    if { [dict exists $qb showdate] && [dict get $qb showdate] } {
		    grid [label $win.main.bl$num -text [mc $w [dict get $qb title]] -anchor w -padx 3] \
		      -column 8 -row [incr row] -sticky nsew
    	  grid [label $win.main.bw$num -text [dict get $qb date] -padx 3] \
    	    -column 9 -row $row -sticky nsew
    	  apply $config_button $w $num Wdate $win.main.bw$num
    	} {
		    grid [label $win.main.bl$num -text [mc $w [dict get $qb title]] -anchor w -padx 3] \
		      -column 8 -row [incr row] -sticky nsew -columnspan 2
		  }
  	  apply $config_button $w $num Wlabel $win.main.bl$num
    }
  }

  update idletasks
  apply {{ win x y } { wm geometry $win "+${x}+${y}" }} $win {*}[winfo pointerxy .]
  switch -- [tk windowingsystem] {
		x11 - win32 { wm transient $win [winfo toplevel $w] }
  }
  wm deiconify $win
  raise $win
}

proc ::ckl::dateentry::qbtn_cmd { event w id } {
  variable cfg
  variable win
  variable save_current
  variable cur_year
  variable cur_month

  lassign [split [clock format [dict get $cfg $w qbuttons $id dateinteger] -format %d-%m-%Y] -] day month year

  if { $event eq "Press" } {
    set cur_year $year
    set cur_month [string trimleft $month 0]
    select_close [string trimleft $day 0]
    return
  }

  if { $event eq "Enter" } {
    if { [dict get $cfg $w qbuttons_jump] } {
		  if { $cur_year ne $year || $cur_month ne [string trimleft $month 0] } {
		    if { ![info exists save_current] } {
			    set save_current [list $cur_month $cur_year]
			  }
		    set cur_month [string trimleft $month 0]
		    set cur_year $year
		    update_view $w
		  }
		}
	  set xevent "hover"
  } elseif { $event eq "Leave" } {
    if { [dict get $cfg $w qbuttons_jump] } {
	    if { [info exists save_current] } {
	      lassign $save_current cur_month cur_year
	      update_view $w
	      unset save_current
	    }
	  }
    set xevent "default"
  }

  if { [dict exists $cfg $w day_widgets "$day$month$year"] } {
      event generate [dict get $cfg $w day_widgets "$day$month$year"] "<Any-${event}>"
  }
  set_color $w [dict get $cfg $w qbuttons $id Wlabel] [list qbutton $xevent]
  if { [dict exists $cfg $w qbuttons $id Wdate] } {
  	set_color $w [dict get $cfg $w qbuttons $id Wdate]  [list qbutton $xevent]
  }
}

proc ::ckl::dateentry::set_color { w W args } {
  variable cfg
  set fg ""
  set bg ""
  set bd ""
  set font ""
  foreach rec [lreverse $args] {
    if { $fg eq "" && [dict exists $cfg $w {*}$rec fg] } {
      set fg [dict get $cfg $w {*}$rec fg]
    }
    if { $bg eq "" && [dict exists $cfg $w {*}$rec bg] } {
      set bg [dict get $cfg $w {*}$rec bg]
    }
    if { $bd eq "" && [dict exists $cfg $w {*}$rec bd] } {
      set bd [dict get $cfg $w {*}$rec bd]
    }
    if { $font eq "" && [dict exists $cfg $w {*}$rec font] } {
      set font [dict get $cfg $w {*}$rec font]
    }
    if { $bg ne "" && $fg ne "" && $bd ne "" && $font ne "" } break
  }
  if { $bg ne "" } { 
    $W configure -background $bg 
    if { [winfo class $W] eq "Button" } {
      $W configure -activebackground $bg 
    }
  }
  if { $fg ne "" } { $W configure -foreground $fg }
  if { $font ne "" } { $W configure -font $font }
  if { $bd ne "" } { foreach {k v} $bd { $W configure $k $v } }
}

proc ::ckl::dateentry::update_view { w } {
  variable cur_year
  variable cur_month
  variable win
  variable days
  variable cfg

  $win.main.header.mon configure -text [lindex [dict get $cfg $w month_list] [expr { $cur_month - 1}]]
  $win.main.header.year configure -text $cur_year

  if { [info exists days] } { destroy {*}$days }
  dict unset cfg $w day_widgets

  set col [clock format [clock scan "$cur_month/1/$cur_year"] -format %u]
  if { ![dict get $cfg $w sunday_first] } {
    incr col -1
  } elseif { $col == 7 } {
    set col 0
  }
  if { $col > 0 } {
    set date [clock scan "$cur_month/1/$cur_year -$col days"]
    set col 0
  } {
    set date [clock scan "$cur_month/1/$cur_year"]
  }
  set row 2
  for { set idx 0 } { $row < 8 || $col > 0 } { incr idx } {
    lassign [split [clock format $date -format %d-%m-%Y] -] day month year
    set W $win.main.day$idx
    dict set cfg $w day_widgets "$day$month$year" $W
    set daytype [expr { [string trimleft $month 0] eq $cur_month ? {days} : {inactive} }]
    label $W -text [string trimleft $day 0] -justify right -anchor e \
      -width 3
    set cmd [list [list $daytype default]]
    switch -- [dict get $cfg $w sunday_first]$col {
      05 - 16 { lappend cmd [list $daytype saturday] }
      06 - 10 { lappend cmd [list $daytype sunday]   }
    }
    if { $daytype eq "days" } {
      if { [dict get $cfg $w today] eq "$day$month$year" } {
        lappend cmd {days today}
      }
	    bind $W <Any-Enter> [namespace code [list set_color $w %W {*}$cmd {days hover}]]
  	  bind $W <Any-Leave> [namespace code [list set_color $w %W {*}$cmd]]
    	bind $W <ButtonRelease> [namespace code [list select_close $day]]
    }
    set_color $w $W {*}$cmd
    grid $W -column $col -row $row -sticky nsew
    if { $col == 6 } { 
      incr row
      set col 0
    } {
      incr col
    }
    lappend days $W
    incr date [expr { 60*60*24 }]
  }
  update idletasks
  set minsize 0
  foreach dayW $days { 
    if { $minsize < [winfo reqheight $dayW] } { 
      set minsize [winfo reqheight $dayW] 
    } 
  }
  for { set row 2 } { $row < 8 } { incr row } {
    grid rowconfigure $win.main $row -minsize $minsize
  }
}

proc ::ckl::dateentry::btn_cmd { w type to } {
  variable cur_year
  variable cur_month

  if { $type eq "mon" } {
    if { $to eq "next" } {
      if { $cur_month >= 12 } return
      incr cur_month
    } {
      if { $cur_month <= 1 } return
      incr cur_month -1
    }
  } {
    if { $to eq "next" } { 
      incr cur_year
    } {
      incr cur_year -1
    }
  }
  update_view $w
}


proc ::ckl::dateentry::widget {w args} {
  variable img_button
  variable cfg

  ttk::frame $w
  pack [ttk::entry $w.entry -width 50] \
       [button $w.button -image $img_button \
         -command [namespace code [list select_open $w]] \
         -relief flat -takefocus 0] -padx 1 -side left

  dict set cfg $w [dict get $cfg defaults]
  foreach id {month year days inactive week_header qbutton} {
    dict set cfg $w $id [dict get $cfg $id]
  }

  if { [llength $args] } {
    configure $w {*}$args
  }

  dict for {k v} [dict get $cfg $w qbuttons] {
    if { ![dict exists $v place] } continue
    dict set cfg $w qbuttons $k dateinteger [parse_date [dict get $cfg $w sunday_first] [dict get $v date]]
    dict set cfg $w qbuttons $k date [clock format [dict get $cfg $w qbuttons $k dateinteger] \
      -format [dict get $cfg $w qbuttons_format]]
    dict set cfg $w qbuttons_[dict get $v place] 1
  }

  for { set i 1 } { $i <= 12 } { incr i } {
    lappend month_list [clock format [clock scan "$i/1"] \
      -format %B -locale [dict get $cfg $w locale]]
  }
  puts $::msgcat::Msgs
  dict set cfg $w month_list $month_list
  for { set i 0 } { $i <= 6 } { incr i } {
    lappend day_list [clock format [clock scan $i -format %u] \
      -format %a -locale [dict get $cfg $w locale]]
  }
  dict set cfg $w day_list $day_list

  bind $w.entry <KeyPress> [namespace code [list entryKey $w %A %K %s]]
  bind $w.entry <<TraverseIn>> [namespace code [list entryTracerseIn $w]]
  bind $w.entry <1> [namespace code [list entryButtonClick $w %x]]
  bind $w.entry <<Paste>> [namespace code [list entryPaste $w]]
	bind $w.entry <Button1-Motion> break
	bind $w.entry <Button2-Motion> break
	bind $w.entry <Double-Button>	 break
	bind $w.entry <Triple-Button>	 break

  set correct 0
  set frmidx -1
  foreach _ [regexp -all -inline -indices %. [dict get $cfg $w format]] {
    set frm [string index [dict get $cfg $w format] [lindex $_ 1]]
    if { $frm eq "%" } {
      incr correct -1
      continue
    }
    set width [string length [clock format 0 -format %$frm]]
    set start [lindex $_ 0]
    incr start $correct
    set end [expr { $start + $width }]
    dict set cfg $w eformat [incr frmidx] \
      [list start $start end $end width $width frm $frm idx $frmidx]
    incr correct [expr { $width - 2 }]
  }
  dict set cfg $w eformat $frmidx last 1
  dict set cfg $w eformat last [dict get $cfg $w eformat $frmidx]
  $w.entry configure -width [expr { [string length [dict get $cfg $w format]] - [lindex $_ 1] - 1 + [dict get $cfg $w eformat last end] }]

  interp hide {} $w
  interp alias {} $w {} ::ckl::dateentry::cmd $w

  trace add command $w {rename delete} [list apply [list {old_w new_w op} {
	  tracectl remove $old_w
	  if { $op eq "rename" } {
		  tracectl add $new_w
	  }  
  } [namespace current]]]

  configure $w -date [dict get $cfg $w date]
  $w.entry icursor [dict get $cfg $w eformat 0 start]

  return $w
}

proc ::ckl::dateentry::cmd {w args} {
  switch -- [lindex $args 0] {
    configure { eval configure $w [lrange $args 1 end] }
    cget      { eval cget $w [lrange $args 1 end]      }
    default   { return [eval $w.entry $args] }
  }
}

proc ::ckl::dateentry::configure {w args} {
  variable cfg
  dict set opts -variable [expr { [dict exists $cfg $w variable_integer] ? [dict get $cfg $w variable_integer] : "" }]
  dict set opts -textvariable [expr { [dict exists $cfg $w variable_string] ? [dict get $cfg $w variable_string] : "" }]
  dict set opts -locale [dict get $cfg $w locale]
  dict set opts -date [dict get $cfg $w date]
  dict set opts -format [dict get $cfg $w format]
  dict set opts -sunday_first [dict get $cfg $w sunday_first]
  switch -- [llength $args] {
    0 {
      return [concat [$w.entry configure] $opts]
    }
    1 {
      if { [dict exists $opts [lindex $args 0]] } {
        return [dict get $opts [lindex $args 0]]
      } {
	      return [$w.entry configure [lindex $args 0]]
	    }
    }
    default {
      foreach {k v} $args {
        switch -- $k {
          -variable {
            tracectl remove $w
            dict set cfg $w variable_integer ::$v
            tracectl add $w
          }
          -textvariable {
            tracectl remove $w
            dict set cfg $w variable_string ::$v
            tracectl add $w
          }
          -locale {
            dict set cfg $w locale $v
          }
          -sunday_first {
            dict set cfg $w sunday_first $v
          }
          -date {
            if { ![string is integer -strict $v] } {
              set v [parse_date [dict get $cfg $w sunday_first] $v]
            }
            dict set cfg $w date $v
            format $w
            tracectl update $w
          }
          -format {
            dict set cfg $w format $v
            format $w
            tracectl update $w
          }
          default {
		        $w.entry configure $k $v
          }
        }
      }
    }
  }
}

proc ::ckl::dateentry::cget {w args} {
  return [lindex [configure $w [lindex $args 0]] end]
}

proc ::ckl::dateentry::mc { w msg args } {
  variable cfg
  variable langdir
  variable langcache

  set locale [dict get $cfg $w locale]
  if { $locale ne "current" } {
    set oldlocale [::msgcat::mclocale]
    ::msgcat::mclocale $locale
  } {
    set locale [::msgcat::mclocale]
  }

  if { ![dict exists ::msgcat::Msgs $locale [::namespace current]] \
    && ![info exists langcache($locale)] } {
    if { [file isdirectory $langdir] } {
      ::msgcat::mcload $langdir
    }
    incr langcache($locale)
  }

  set r [::msgcat::mc $msg {*}$args]
  if { [info exists oldlocale] } {
    ::msgcat::mclocale $oldlocale
  }
  return $r
}

interp alias {} ::dateentry {} ::ckl::dateentry::widget


proc ::ckl::dateentry::fixUKlocale { } {
  set oldLocale [::msgcat::mclocale]
  ::msgcat::mclocale uk
	::msgcat::mcload $::tcl::clock::MsgDir
	::msgcat::mclocale $oldLocale

  # replace UK locale messages
  set a {
	    MONTHS_FULL {Січень Лютий Березень Квітень Травень Червень Липень Серпень Вересень Жовтень Листопад Грудень {}}
	    MONTHS_ABBREV {Січ Лют Бер Кві Тра Чер Лип Сер Вер Жов Лис Гру}
	    DAYS_OF_WEEK_FULL {Неділя Понеділок Вівторок Середа Четвер П’ятниця Субота}
	    DAYS_OF_WEEK_ABBREV {Нд Пн Вт Ср Чт Пт Сб}
	}
  dict set ::tcl::clock::McLoaded uk $a
	dict set ::msgcat::Msgs uk ::tcl::clock $a
}
::ckl::dateentry::fixUKlocale


