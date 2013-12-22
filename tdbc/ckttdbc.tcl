package require tdbc

package provide ckl::tdbc 1.0

oo::define ::tdbc::connection {
  method onecolumn { args } {
    try {
      set r [uplevel 1 [concat [list [self] allrows] $args]]
    } on error {r o} {
      return -options $o $r
    }
    set result [list]
    foreach _ $r { lappend result [lindex $_ 1] }
    return $result
  }
  method onevalue { args } {
    try {
      set r [uplevel 1 [concat [list [self] allrows] $args]]
    } on error {r o} {
      return -options $o $r
    }
    return [lindex [lindex $r 0] 1]
  }
}
