package require procarg
package require http
package require checkonline

namespace eval  ::proxylist {
  namespace import ::checkonline::checkonline

  variable Requests
  variable RequestCallback
  variable Tags
  variable ProxylistRAW [list]
  variable ProxylistCHK [list]
  variable ProxylistBAN [list]
  variable ProxylistOK  [list]
  # how many request for one proxy
  variable DefaultRequests -1
  # when proxy out from "used proxy" list
  variable DefaultTimeout [expr { 60*60 }]

  variable CheckTimeout [expr { 60*30 }]
  variable CheckThreadsMax 20
  variable ReqCounter 0
  variable Status     ""

  variable Debug 1


  array set Requests [list]
  array set Tags [list]

  proc log { msg } {
    variable Debug
    if { !$Debug } return
    puts "\[proxycheck\] $msg"
  }

  proc getproxy { { args {
    {-tag      string -default ""}
    {-callback string}
  }}} {
    variable ReqCounter
    variable Tags
    variable Requests
    variable RequestCallback
    variable DefaultRequests
    variable DefaultTimeout

    set req [incr ReqCounter]
    log "new request $req"
    set Requests($req) [dict create tag $opts(-tag)]
    foreach {k v} [list MaxRequests $DefaultRequests Timeout $DefaultTimeout] {
	    if { ![info exists Tags([list $opts(-tag) $k])] } {
	      log "set default tag options $opts(-tag) $k -> $v"
	      set Tags([list $opts(-tag) $k]) $v
	    }
	  }
    if { [info exists opts(-callback)] } {
      log "callback exists, call next"
      dict set Requests($req) callback $opts(-callback)
      getproxy_
      return
    }
    log "make&vait selfcallback for non-interactive"
    dict set Requests($req) callback [list apply [list args {
      variable RequestCallback
      set RequestCallback {*}$args
    } [namespace current]]]
    getproxy_
    vwait RequestCallback
    set result $RequestCallback
    unset RequestCallback
    log "return value $result"
    return $result
  }

  proc getproxy_ { } {
    variable Requests
    variable Tags
    variable ProxylistOK
    variable ProxylistRAW
    variable CheckTimeout
    variable Status
    if { ![array size Requests] } return
    foreach req [array names Requests] {
      set tag [dict get $Requests($req) tag]
      log "found req $req with tag $tag"
      #if current proxy for tag exists - then check for max requests
      if { [info exists Tags([list $tag current])] && [lindex $Tags([list $tag current]) 1] >= $Tags([list $tag MaxRequests]) } {
        lappend Tags([list $tag used]) [list [lindex $Tags([list $tag current]) 0 0] [lindex $Tags([list $tag current]) 2]]
        log "tag reach max requests [lindex $Tags([list $tag current]) 1] for current proxy [lindex $Tags([list $tag current]) 0]"
        unset Tags([list $tag current])
      }
      if { ![info exists Tags([list $tag current])] } {
        log "no current proxy for tag $tag"
	      #cleanup used proxylist for tag
	      set newlist [list]
	      foreach proxy $Tags([list $tag used]) {
	        lassign $proxy host timestamp
	        if { ($timestamp + $Tags([list $tag Timeout])) < [clock seconds] } {
	          lappend newlist [list $host $timestamp]
	        } {
	          log "remove used proxy $host as timeout"
	        }
	      }
	      set Tags([list $tag used]) $newlist
	      unset newlist
	      unset -nocomplain proxy host timestamp
        #cleanup ProxylistOK
        if { ![info exists ProxylistOKcleanup] } {
          log "test ProxylistOK for checktimeout..."
	        set newlist [list]
	        foreach proxy $ProxylistOK {
	          lassign $proxy proxy lastcheck
	          if { ($lastcheck + $CheckTimeout) >= [clock seconds] } {
	            lappend ProxylistRAW $proxy
	          } {
	            lappend newlist [list $proxy $lastcheck]
	          }
	        }
	        set ProxylistOK $newlist
	        set ProxylistOKcleanup 1
	        unset newlist
	        unset -nocomplain proxy lastcheck
	      }
	      # try to find proxy for tag
	      foreach proxy $ProxylistOK {
	        if { [lsearch -exact -index 0 $Tags([list $tag used]) [lindex $proxy 0]] != -1 } continue
          set Tags([list $tag current]) [list $proxy 0 [clock seconds]]
          log "found new proxy, suitable for tag $proxy"
          break
	      }
	      unset -nocomplain proxy
	    }
	    if { [info exists $Tags([list $tag current])] } {
	      log "start callback for request"
	      set Tags([list $tag current]) [list [lindex $Tags([list $tag current]) 0] [expr { [lindex $Tags([list $tag current]) 1] + 1 }] [clock seconds]]
	      after 0 [linsert [dict get $Requests($req) callback] end ok {*}[lindex $Tags([list $tag current]) 0]]
	      unset Request($req)
	    } {
		    log "no proxy for tag '$tag' for now, try to update proxy"
	      updateproxy
		  }
	  }

    if { [llength $ProxylistRAW] } {
      check
    }

  }

  proc updateproxy { } {
    variable Status
    set Status "update"
    log "update all proxy"
    # run update for all modules
  }

  proc check { } {
    variable ProxylistRAW
    variable ProxylistCHK
    variable ProxylistBAN
    variable CheckThreadsMax
    # if we are not online, then continue after we get online
    if { ![checkonline -ononline [namespace current]::check] } return
    while { ([llength $ProxylistCHK] < $CheckThreadsMax) && [llength $ProxylistRAW] } {
      set proxy [lindex $ProxylistRAW 0]
      set ProxylistRAW [lreplace $ProxylistRAW 0 0]
      lappend ProxylistCHK $proxy
	    set save [::http::config]
      ::http::config -proxyhost [lindex $proxy 0]
      ::http::config -proxyport [lindex $proxy 1]
      log "test proxy $proxy ..."
      try {
	      set token [::http::geturl "http://www.iprivacytools.com/proxy-checker-anonymity-test/" -timeout 10000 \
					  	      -command [list [namespace current]::check_ $proxy [clock milliseconds]]]
  	  } on error { r o } {
  	    log "internal error for proxy $proxy"
  	    lappend ProxylistBAN $proxy
  	    set ProxylistCHK [lreplace $ProxylistCHK end end]
  	  }
  	  ::http::config {*}$save
      unset save
    }
  }

  proc check_ { proxy timestamp token } {
    variable ProxylistCHK
    variable ProxylistOK
    variable ProxylistBAN
    set idx [lsearch -exact $ProxylistCHK $proxy]
    set ProxylistCHK [lreplace $ProxylistCHK $idx $idx]
    log "check proxy result $proxy : [::http::status $token]; code - [::http::ncode $token]"
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      log "check proxy result $proxy : OK!"
      if { [string first {NO PROXY DETECTED (Scroll down for details)} [::http::data $token]] != -1 } {
        log "check proxy result $proxy : OK - anonymous!"
        lappend ProxylistOK $proxy
        after 0 [namespace current]::getproxy_
      } {
        log "check proxy result $proxy : BAN - NOT anonymous!"
        lappend ProxylistBAN $proxy
      }
    } {
      log "check proxy result $proxy : BAN for status."
      lappend ProxylistBAN $proxy
    }
  	::http::cleanup $token
  	after 0 [namespace current]::check
  }

}

package provide proxylist 1.0
