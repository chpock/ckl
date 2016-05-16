package require procarg
package require http
package require ckl::checkonline

namespace eval  ::proxylist {
  namespace import ::checkonline::checkonline
  namespace export getproxy
  namespace export httpreq

  variable Requests
  variable RequestCallback
  variable Tags
  variable ProxylistRAW [list]
  variable ProxylistCHK [list]
  variable ProxylistBAN [list]
  variable ProxylistOK  [list]

  # Default variables for tag
  # how many request for one proxy
  variable DefaultRequests 30
  # when proxy out from "used proxy" list, default - 1h
  variable DefaultTimeout [expr { 60*60 }]

  # how many good proxy lookup in one time
  variable NeedGoodProxyMAX 15
  # internal counter for max lookup
  variable NeedGoodProxy 0
  # when recheck proxy for working, default - 2h
  variable CheckTimeout [expr { 60*20*2 }]
  variable CheckThreadsMax 5
  variable ReqCounter 0
  variable Status     ""

  variable Debug 1


  array set Requests [list]
  array set Tags [list]
  array set RequestCallback [list]

  proc log { msg } {
    variable Debug
    if { !$Debug } return
#    set fd [open a.log a+]
#    puts $fd "\[proxycheck\] $msg"
#    close $fd
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
	      log "set default tag options '$opts(-tag)' $k -> $v"
	      set Tags([list $opts(-tag) $k]) $v
	    }
	  }
    if { [info exists opts(-callback)] && $opts(-callback) ne "" } {
      log "add callback in queue"
      dict set Requests($req) callback $opts(-callback)
      getproxy_
      return
    }
    log "make&vait selfcallback for non-interactive"
    dict set Requests($req) callback [list apply [list {req args} {
      variable RequestCallback
      set RequestCallback($req) $args
    } [namespace current]] $req]
    getproxy_
    vwait [namespace current]::RequestCallback($req)
    set result $RequestCallback($req)
    unset RequestCallback($req)
    log "return value {*}$result"
    return $result
  }

  proc getproxy_ { } {
    variable Requests
    variable Tags
    variable ProxylistOK
    variable ProxylistRAW
    variable ProxylistCHK
    variable CheckTimeout
    variable Status
    variable NeedGoodProxyMAX
    variable NeedGoodProxy
    if { ![array size Requests] } return
    foreach req [array names Requests] {
      set tag [dict get $Requests($req) tag]
      log "found req $req with tag '$tag'"
      #if current proxy for tag exists - then check for max requests
      if { [info exists Tags([list $tag current])] && $Tags([list $tag MaxRequests]) > 0 && [lindex $Tags([list $tag current]) 1] >= $Tags([list $tag MaxRequests]) } {
        lappend Tags([list $tag used]) [list [lindex $Tags([list $tag current]) 0 0] [lindex $Tags([list $tag current]) 2]]
        log "tag reach max requests [lindex $Tags([list $tag current]) 1] for current proxy [lindex $Tags([list $tag current]) 0]"
        unset Tags([list $tag current])
      }
      if { ![info exists Tags([list $tag current])] } {
        log "no current proxy for tag '$tag'"
	      #cleanup used proxylist for tag
	      if { [info exists Tags([list $tag used])] } {
		      set newlist [list]
		      foreach proxy $Tags([list $tag used]) {
		        lassign $proxy host timestamp
		        if { ($timestamp + $Tags([list $tag Timeout])) >= [clock seconds] } {
		          lappend newlist [list $host $timestamp]
		        } {
		          log "remove used proxy $host as timeout"
		        }
		      }
		      set Tags([list $tag used]) $newlist
		      unset newlist
		      unset -nocomplain proxy host timestamp
		    }
        #cleanup ProxylistOK
        if { ![info exists ProxylistOKcleanup] } {
          log "test ProxylistOK for checktimeout..."
	        set newlist [list]
	        foreach proxy $ProxylistOK {
	          lassign $proxy proxy lastcheck rating
	          if { ($lastcheck + $CheckTimeout) >= [clock seconds] } {
	            lappend newlist [list $proxy $lastcheck $rating]
	          } {
	            lappend ProxylistRAW $proxy
	          }
	        }
	        set ProxylistOK $newlist
	        set ProxylistOKcleanup 1
	        unset newlist
	        unset -nocomplain proxy lastcheck rating
	      }
	      # try to find proxy for tag
	      foreach proxy $ProxylistOK {
	        set proxy [lindex $proxy 0]
	        if { [info exists Tags([list $tag used])] && [lsearch -exact -index 0 $Tags([list $tag used]) [lindex $proxy 0]] != -1 } continue
          set Tags([list $tag current]) [list $proxy 0 [clock seconds]]
          log "found new proxy, suitable for tag : $proxy"
          break
	      }
	      unset -nocomplain proxy
	    }
	    if { [info exists Tags([list $tag current])] } {
	      set Tags([list $tag current]) [list [lindex $Tags([list $tag current]) 0] [expr { [lindex $Tags([list $tag current]) 1] + 1 }] [clock seconds]]
	      log "start callback for request, counter: [lindex $Tags([list $tag current]) 1]"
	      log "callback: [linsert [dict get $Requests($req) callback] end ok {*}[lindex $Tags([list $tag current]) 0]]"
	      after 0 [linsert [dict get $Requests($req) callback] end ok {*}[lindex $Tags([list $tag current]) 0]]
	      unset Requests($req)
	    } {
        if { [llength $ProxylistRAW] || [llength $ProxylistCHK] } {
	 		    log "no proxy for tag '$tag' for now, try to check exists proxys"
	 		    if { ![info exists start_check] } {
	 		      set NeedGoodProxy $NeedGoodProxyMAX
	          check
	          set start_check 1
	        }
        } {	      
	 		    log "no proxy for tag '$tag' for now, try to update proxy"
	 		    if { ![info exists start_update] } {
			      updateproxy
			      set start_update 1
			    }
		    }
		  }
	  }
  }

  proc updateproxy { } {
    variable Status
    if { $Status eq "update" } return
    log "update all proxy"
    foreach ns [namespace children [namespace current]] {
      if { [info commands ${ns}::updateproxy] ne "" } {
        if { [info exists ${ns}::Status] && [set ${ns}::Status] in {"update" "error"} } continue
        log "start update proxymod $ns ..."
        if { [catch {${ns}::updateproxy} errmsg] } {
          log "error while update proxymod on $ns"
          set ${ns}::Status "error"
        } {
          set ${ns}::Status "update"
			    set Status "update"
        }
      }
    }
  }

  proc httpreq { url args } {
    set ns [uplevel 1 {namespace current}]
    checkonline -callback [list [namespace current]::httpreq_ $ns $url $args]
  }

  proc httpreq_ { ns url arg } {
    set save [::http::config]
    ::http::config -proxyhost ""
    ::http::config -proxyport ""
    log "req proxyupdate on $url"
    try {
      set token [::http::geturl $url {*}$arg -timeout 5000 \
                  -headers [list {Accept-Language} {ru-RU} {Accept-Encoding}	{gzip, deflate}] \
  			  	      -command [list apply {args { after 0 $args }} [namespace current]::httpreq_callback $ns]]  			  	      
    } on error { r o } {
  	  log "req proxyupdate int error: $r"
 	    catch { ::http::cleanup $token }
 	    tailcall httpreq_done $ns "error" ""
  	} finally {
	  	::http::config {*}$save
	    unset save
	  }
  }

  proc httpreq_callback { ns token } {
    log "req proxyupdate callback $ns : status - [::http::status $token]; code - [::http::ncode $token]"
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      set data [::http::data $token]
      set status "ok"
    } {
      set data ""
      set status "error"
    }
    tailcall httpreq_done $ns $status $data
  }

  proc httpreq_done { ns status data } {
	  variable ProxylistRAW
  	variable ProxylistCHK
  	variable ProxylistBAN
  	variable ProxylistOK
  	variable Status
    if { $status eq "ok" } {
      log "req proxyupdate parse $ns"
      if { [catch {${ns}::callback $data} result] } {
        log "req proxyupdate parse error: $result"
      } {
        log "req proxyupdate parse get [llength $result] proxys"
        foreach proxy $result {
          if { [lsearch -exact $ProxylistRAW $proxy] != -1 } {
#            log "proxy $proxy in RAW list"
          } elseif { [lsearch -exact $ProxylistBAN $proxy] != -1 } {
#            log "proxy $proxy in BAN list"
          } elseif { [lsearch -exact $ProxylistCHK $proxy] != -1 } {
#            log "proxy $proxy in CHK list"
          } elseif { [lsearch -exact -index 0 $ProxylistOK $proxy] != -1 } {
#            log "proxy $proxy in OK list"
          } else {
#            log "add new proxy $proxy"
            lappend ProxylistRAW $proxy
          }
        }
      }
	  	after 0 [namespace current]::check
      after 0 [namespace current]::getproxy_
    }
    unset ${ns}::Status
    foreach ns [namespace children [namespace current]] {
      if { [info commands ${ns}::updateproxy] ne "" } {
        if { [info exists ${ns}::Status] && [set ${ns}::Status] eq "update" } {
          log "found active update thread, dont change update status for proxylist"
          return
        }
      }
    }
    log "no active update thread, empty proxylist status"
    set Status ""
  }

  proc check { } {
    checkonline -callback [namespace current]::check_
  }

  proc check_ { } {
    variable NeedGoodProxy
    variable ProxylistRAW
    variable ProxylistCHK
    variable ProxylistBAN
    variable CheckThreadsMax
    if { $NeedGoodProxy <= 0 } return
    while { ([llength $ProxylistCHK] < $CheckThreadsMax) && [llength $ProxylistRAW] } {
      set proxy [lindex $ProxylistRAW 0]
      set ProxylistRAW [lreplace $ProxylistRAW 0 0]
      lappend ProxylistCHK $proxy
	    set save [::http::config]
      ::http::config -proxyhost [lindex $proxy 0]
      ::http::config -proxyport [lindex $proxy 1]
      log "test proxy $proxy ..."
      try {
	      set token [::http::geturl "http://www.find-ip.net/proxy-checker" -timeout 5000 \
                    -headers [list {Accept-Language} {ru-RU} {Accept-Encoding}	{gzip, deflate}] \
					  	      -command [list apply {args { after 0 $args }} [namespace current]::check_callback $proxy [clock milliseconds]]]
  	  } on error { r o } {
  	    log "internal error for proxy $proxy"
  	    catch { ::http::cleanup $token }
  	    lappend ProxylistBAN $proxy
  	    set ProxylistCHK [lreplace $ProxylistCHK end end]
  	  } finally {
	  	  ::http::config {*}$save
	      unset save
	    }
    }
  }

  proc check_callback { proxy timestamp token } {
    variable NeedGoodProxy
    variable ProxylistCHK
    variable ProxylistOK
    variable ProxylistBAN
    set idx [lsearch -exact $ProxylistCHK $proxy]
    set ProxylistCHK [lreplace $ProxylistCHK $idx $idx]
    unset idx
    log "check proxy result $proxy : [::http::status $token]; code - [::http::ncode $token]"
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      log "check proxy result $proxy : OK!"
      if { [string first {No proxy is detected.} [::http::data $token]] != -1 } {
        log "check proxy result $proxy : OK - anonymous!"
        lappend ProxylistOK [list $proxy [clock seconds] [expr { [clock milliseconds] - $timestamp }]]
        set ProxylistOK [lsort -integer -increasing -index 2 $ProxylistOK]
        incr NeedGoodProxy -1
        after 0 [namespace current]::getproxy_
      } {
        log "check proxy result $proxy : BAN - NOT anonymous!"
        lappend ProxylistBAN $proxy
      }
    } {
      log "check proxy result $proxy : BAN for status."
      lappend ProxylistBAN $proxy
    }
  	catch { ::http::cleanup $token }
  	after 0 [namespace current]::check
  	after 0 [namespace current]::getproxy_
  }

}

package provide ckl::proxylist 1.0
