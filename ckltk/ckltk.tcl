package provide ckl::tk 1.0

proc % {{_ ""}} {
  if { ![info exists ::___uid___] } { set ::___uid___ 0 }
  if { $_ ne "" && $_ ne "." } { append _ .  }
  return [append _ [incr ::___uid___]]
}

proc img {id} {
  set iid "img-$id"
  if { [lsearch -exact [image names] $iid] != -1 } { return $iid }
  set frm "gif"
  if { ![file exists [set fn [file join $::starkit::topdir images "${id}.gif"]]] } {
    set fn [file join $::starkit::topdir images "${id}.png"]
    set frm "png"
  }
  return [image create photo $iid -file $fn -format $frm]
}

proc centerwin d {
  wm withdraw $d
  update idletasks
  set width [winfo reqwidth $d]
  set height [winfo reqheight $d]
  set x [expr { [winfo x .] + [winfo width .]/2 - $width/2 }]
  set y [expr { [winfo y .] + [winfo height .]/2 - $height/2 }]
  if { $x < 0 } { set x 10 }
  if { $y < 0 } { set y  10 }
  wm geometry $d ${width}x${height}+${x}+${y}
  wm deiconify $d
}


event add <<Paste>> <Control-Key-igrave> <Control-Key-Igrave> <Control-Lock-Key-igrave> <Control-Lock-Key-Igrave>
event add <<Copy>> <Control-Key-ntilde> <Control-Key-Ntilde> <Control-Lock-Key-ntilde> <Control-Lock-Key-Ntilde>
event add <<Cut>> <Control-Key-division> <Control-Key-multiply> <Control-Lock-Key-division> <Control-Lock-Key-multiply>