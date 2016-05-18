package require procarg
package require http

namespace eval ::checkonline {
  namespace export checkonline
  
  variable Callbacks
  variable LastcheckTimestamp
  variable LastcheckValue   0
  variable CheckTimeoutGood [expr { 60 * 10 }]
  variable CheckTimeout     60
  variable Debug 0
  variable Status ""
  variable uid

  variable Log {
    INFO-RESET        "reset callback"
    ERROR-RESET       "callback not found"
    INFO-TIMER        "set timer"
    INFO-SAVECALLBACK "save callback"
    INFO-AUTOOK       "return auto-ok value"
    INFO-WAIT         "in wait mode now"
    INFO-CALLBACK     "fire callback"
    INFO-REQUEST      "making request"
    ERROR-REQUESTINT  "internal error"
    INFO-REQUESTCALLBACK "request callback"
    INFO-REQUESTOK    "request ok"
    ERROR-REQUESTDATA "request error - bad data"
    ERROR-REQUESTCODE "request error - bad code/status"
  }

  proc log { id {detail {}} } {
    variable Debug
    variable Log
    if { !$Debug } return
    set str [dict get $Log $id]
    if { $detail ne "" } {
      append str ", detail: $detail"
    }
    puts "\[checkonline\] $str"
  }

  proc reset { uid } {
    variable Callbacks
    if { [array exists Callbacks] && [info exists Callbacks($uid)] } {
      unset Callbacks($uid)
      log "INFO-RESET" $uid
    } {
      log "ERROR-RESET" $uid
    }
  }

  proc settimer { } {
    variable CheckTimeout
    variable Status
    log "INFO-TIMER"
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

    log "INFO-SAVECALLBACK" $uid

    if { $Status eq "" && $LastcheckValue && ($CheckTimeoutGood + $LastcheckTimestamp) >= [clock seconds] } {
      log "INFO-AUTOOK"
      runcallbacks
      return $uid
    }

    if { $Status in {"query" "timer"} } {
      log "INFO-WAIT" "status - $Status"
    } {
	    query
    }

    return $uid
  }

  proc runcallbacks { } {
    variable Callbacks
    foreach id [array names Callbacks] {
      log "INFO-CALLBACK" $id
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
      log "INFO-REQUEST"
      set token [::http::geturl "http://www.find-ip.net/proxy-checker" -timeout 2000 -command \
        [list apply {args { after 0 $args }} [namespace current]::callback] \
      ]
    } on error { r o } {
      log "ERROR-REQUESTINT" $r
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
    log "INFO-REQUESTCALLBACK" "status - [::http::status $token]; code - [::http::ncode $token]"
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      if { [string first {About Didsoft} [::http::data $token]] != -1 } {
        log "INFO-REQUESTOK"
        set online 1
      } {
        log "ERROR-REQUESTDATA"
      }
    } {
      log "ERROR-REQUESTCODE"
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
