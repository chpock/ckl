package require procarg

package provide ckl::dialogs 1.0

namespace eval dialogs {
	namespace export *
	namespace ensemble create

	variable saves

	procarg register init {
		{-title      string}
		{-return-ok switch}
		{-esc-cancel switch}
	}

	procarg register run {
		{0 string -allowempty false}
		{-focus string}
	}
}

proc dialogs::init { args } {
	procarg parse

	variable saves

	set w [% .]

	set saves(${w}.focus) [focus]
	set saves(${w}.grab) [grab current .]

	set s "::dialogs::saves(${w}.state)"
	set sok [list set $s 1]
	set scancel [list set $s 0]

	toplevel $w -bd 1 -relief raised -class TkSDialog
	wm title $w $opts(-title)
	wm iconname $w $opts(-title)
	wm protocol  $w WM_DELETE_WINDOW $scancel
	wm transient $w [winfo toplevel [winfo parent $w]]

  bind $w <Destroy> $scancel
	if { $opts(-return-ok) } { bind $w <Return> $sok }
	if { $opts(-esc-cancel) } { bind $w <Escape> $scancel }

	return [list $w $s $sok $scancel]
}

proc dialogs::run {w args} {

	procarg parse

	variable saves

	set s "::dialogs::saves(${w}.state)"

	wm withdraw $w
  update idletasks
  if { $opts(-focus) eq "" } {
  	focus $w
  } {
  	focus $opts(-focus)
  }
  set x [expr {[winfo screenwidth  $w]/2 - [winfo reqwidth  $w]/2 - [winfo vrootx $w]}]
  set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2 - [winfo vrooty $w]}]
  wm geom $w +$x+$y
  wm deiconify $w
  grab $w

	tkwait variable $s

	return [set $s]	
}

proc dialogs::done { w } {
	variable saves
  bind $w <Destroy> {}
  grab release $w
  destroy $w
  focus -force $saves(${w}.focus)
  if {$saves(${w}.grab) != ""} { grab $saves(${w}.grab) }
  update idletasks

  unset saves(${w}.focus)
  unset saves(${w}.grab)
  unset saves(${w}.state)
}




