package require procarg
package require http

namespace eval ::checkonline {
  namespace export checkonline
  
  variable Callbacks
  variable LastcheckTimestamp
  variable LastcheckValue
  variable CheckTimeoutGood [expr { 60 * 10 }]
  variable CheckTimeoutBad  [expr { 60 * 5 }]
  variable CheckTimeout     60
  variable CheckTimer
  variable Debug 1

  proc log { msg } {
    variable Debug
    if { !$Debug } return
    puts "\[checkonline\] $msg"
  }

  proc checkonline { {args {
    {-ononline string}
  }}} {
    variable Callbacks
    variable LastcheckTimestamp
    variable LastcheckValue
    variable CheckTimeoutGood
    variable CheckTimeoutBad

    if { [info exists LastcheckValue] } {
      if { $LastcheckValue && ($CheckTimeoutGood + $LastcheckTimestamp) < [clock seconds] } {
        log "auto return ok"
        return 1
      }
      if { !$LastcheckValue && ($CheckTimeoutBad + $LastcheckTimestamp) < [clock seconds] } {
        if { [info exists opts(-ononline)] && (![info exists $Callbacks] || [lsearch -exact $Callbacks $opts(-ononline)] == -1) } {
          log "save callback $opts(-ononline)"
          lappend Callbacks $opts(-ononline)
        }
        if { ![info exists CheckTimer] && [info exists Callbacks] } {
          log "auto query next check"
          set CheckTimer [after [expr { $CheckTimeout * 1000 }] [namespace current]::checkonlinetimer]
        }
        log "auto return bad"
        return 0
      }
    }

    set save [::http::config]
    ::http::config -proxyhost ""
    ::http::config -proxyport ""
    try {
      log "make request"
      set token [::http::geturl "http://www.iprivacytools.com/proxy-checker-anonymity-test/" -timeout 2000]
      log "result: status - [::http::status $token]; code - [::http::ncode $token]"
      if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
        if { [string first {Your privacy is important to us} [::http::data $token]] != -1 } {
          log "result: data - ok"
          set iamonline 1
        } {
          log "result: data - bad"
        }
      }
    } on error { r o } {
      log "request error: $r"
    } finally {
      log "cleanup"
  	  ::http::config {*}$save
  	  ::http::cleanup $token
  	}

 	  set LastcheckTimestamp [clock seconds]
  	if { [info exists iamonline] } {
  	  set LastcheckValue 1
  	  if { [info exists Callbacks] } {
	  	  foreach callback $Callbacks {
	  	    log "activate callback: $callback"
	  	    after 0 $callback  
	  	  }
	  	  unset Callbacks
	  	}
  	  log "return OK"
  	  return 1
  	} {
  	  set LastcheckValue 0
  	  if { [info exists opts(-ononline)] && (![info exists $Callbacks] || [lsearch -exact $Callbacks $opts(-ononline)] == -1) } {
  	    log "save callback $opts(-ononline)"
  	    lappend Callbacks $opts(-ononline)
  	  }
  	  if { ![info exists CheckTimer] && [info exists Callbacks] } {
  	    log "query next check"
  	    set CheckTimer [after [expr { $CheckTimeout * 1000 }] [namespace current]::checkonlinetimer]
  	  }
  	  log "return BAD"
  	  return 0
  	}
  }

  proc checkonlinetimer { } {
    variable CheckTimer
    unset CheckTimer
    log "check timer"
    checkonline
  }

}

package provide checkonline 1.0
