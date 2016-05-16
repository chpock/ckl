package ifneeded ckl::proxylist 1.0 [list apply {{dir} {
  source [file join $dir proxylist.tcl]
  foreach fn [glob -nocomplain -directory $dir "proxymodule-*.tcl"] {
    source $fn  
  }
  unset -nocomplain fn
}} $dir]
