package require procarg
package require http

namespace eval ::checkonline {
  namespace export checkonline
  
  variable Callbacks        [list]
  variable LastcheckTimestamp
  variable LastcheckValue   0
  variable CheckTimeoutGood [expr { 60 * 10 }]
  variable CheckTimeout     60
  variable Debug 1
  variable Status ""

  proc log { msg } {
    variable Debug
    if { !$Debug } return
    puts "\[checkonline\] $msg"
  }

  proc settimer { } {
    variable CheckTimeout
    variable Status
    log "auto query next check"
    set Status "timer"
    after [expr { $CheckTimeout * 1000 }] [list [namespace current]::checkonline -timer]
  }

  proc checkonline { {args {
    {-callback string}
    {-timer switch}
  }}} {
    variable Callbacks
    variable LastcheckTimestamp
    variable LastcheckValue
    variable CheckTimeoutGood
    variable Status

    if { [info exists opts(-callback)] && $opts(-callback) ne "" && [lsearch -exact $Callbacks $opts(-callback)] == -1 } {
      log "save callback $opts(-callback)"
      lappend Callbacks $opts(-callback)
    }

    if { $Status eq "query" || ($Status eq "timer" && !$opts(-timer)) } {
      log "in $Status mode now, return false"
      return 0
    }

    if { $Status eq "" && $LastcheckValue && ($CheckTimeoutGood + $LastcheckTimestamp) >= [clock seconds] } {
      log "auto return ok"
      foreach callback $Callbacks {
        log "fire callback: $callback"
        after 0 $callback
      }
      set Callbacks [list]
      return 1
    }

    set Status "query"
    set save [::http::config]
    ::http::config -proxyhost ""
    ::http::config -proxyport ""
    try {
      log "make request"
      set token [::http::geturl "http://www.find-ip.net/proxy-checker" -timeout 2000 -command \
        [list apply {args { after 0 $args }} [namespace current]::callback] \
      ]
    } on error { r o } {
      log "request error: $r"
      set LastcheckValue 0
      set LastcheckTimestamp [clock seconds]
  	  catch { ::http::cleanup $token }
      settimer
    } finally {
      log "cleanup request"
  	  ::http::config {*}$save
    }

    log "enter in $Status mode, return false"

    return 0
  }

  proc callback { token } {
    variable LastcheckValue
    variable LastcheckTimestamp
    variable Status
    log "callback: status - [::http::status $token]; code - [::http::ncode $token]"
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      if { [string first {About Didsoft} [::http::data $token]] != -1 } {
        log "callback: data - ok"
        set online 1
      } {
        log "callback: data - bad"
      }
    }
    ::http::cleanup $token
    set LastcheckValue [info exists online]
    set LastcheckTimestamp [clock seconds]
    if { $LastcheckValue } {
     set Status ""
     tailcall checkonline
    } {
      settimer
    }
  }

}

package provide ckl::checkonline 1.0
