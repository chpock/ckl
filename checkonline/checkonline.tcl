package require procarg
package require http

namespace eval ::checkonline {
  namespace export checkonline
  
  variable Callbacks
  variable LastcheckTimestamp
  variable LastcheckValue   0
  variable CheckTimeoutGood [expr { 60 * 10 }]
  variable CheckTimeout     60
  variable Debug 1
  variable Status ""
  variable uid

  proc log { id desc hdesc1 {hdesc2 {}} } {
    variable Debug
    if { !$Debug } return
    if { $hdesc2 eq "" } {
      set hdesc2 $hdesc1
    }
    puts "\[checkonline\] ${id}-${desc} >> $hdesc2"
  }

  proc settimer { } {
    variable CheckTimeout
    variable Status
    log "INFO" "TIMER" "set timer"
    set Status "timer"
    after [expr { $CheckTimeout * 1000 }] [list [namespace current]::query]
  }

  proc checkonline { {args {
    {-callback string -nodefault -allowempty false}
  }}} {
    variable Callbacks
    variable LastcheckTimestamp
    variable LastcheckValue
    variable CheckTimeoutGood
    variable Status
    variable uid

    set Callbacks([incr uid]) $opts(-callback)

    log "INFO" "SAVECALLBACK" "save callback" "save callback: $opts(-callback)"

    if { $Status eq "" && $LastcheckValue && ($CheckTimeoutGood + $LastcheckTimestamp) >= [clock seconds] } {
      log "INFO" "AUTOOK" "return auto-ok value"
      runcallbacks
      return $uid
    }

    if { $Status in {"query" "timer"} } {
      log "INFO" "WAIT" "in $Status mode now"
    } {
	    query
    }

    return $uid
  }

  proc runcallbacks { } {
    variable Callbacks
    foreach id [array names Callbacks] {
      log "INFO" "CALLBACK" "fire callback" "fire callback: $Callbacks($id)"
      after 0 $Callbacks($id)
      unset Callbacks($id)
    }
  }

  proc query { } {
    variable Status
    set Status "query"
    set save [::http::config]
    ::http::config -proxyhost ""
    ::http::config -proxyport ""
    try {
      log "INFO" "REQUEST" "making request"
      set token [::http::geturl "http://www.find-ip.net/proxy-checker" -timeout 2000 -command \
        [list apply {args { after 0 $args }} [namespace current]::callback] \
      ]
    } on error { r o } {
      log "ERROR" "REQUEST" "internal error" "internal error: $r"
      set LastcheckValue 0
      set LastcheckTimestamp [clock seconds]
  	  catch { ::http::cleanup $token }
      settimer
    } finally {
  	  ::http::config {*}$save
    }
  }

  proc callback { token } {
    variable LastcheckValue
    variable LastcheckTimestamp
    variable Status
    log "INFO" "REQUESTCALLBACK" "request callback" "request callback: status - [::http::status $token]; code - [::http::ncode $token]"
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      if { [string first {About Didsoft} [::http::data $token]] != -1 } {
        log "INFO" "REQUESTOK" "request ok"
        set online 1
      } {
        log "ERROR" "REQUEST" "request error" "bad data"
      }
    } {
      log "ERROR" "REQUEST" "request error" "request error code/status"
    }
    ::http::cleanup $token
    set LastcheckValue [info exists online]
    set LastcheckTimestamp [clock seconds]
    if { $LastcheckValue } {
      set Status ""
      tailcall runcallbacks
    } {
      tailcall settimer
    }
  }

}

package provide ckl::checkonline 1.0
