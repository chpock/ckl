package require procarg
package require http
package require ckl::checkonline

namespace eval  ::proxylist {
  namespace import ::checkonline::checkonline
  namespace export getproxy
  namespace export httpreq
  namespace export configproxy
  namespace export forcebanproxy

  variable Requests
  variable RequestCallback
  variable Tags
  variable ProxylistRAW [list]
  variable ProxylistCHK [list]
  variable ProxylistBAN [list]
  variable ProxylistOK  [list]

  # Default variables for tag
  # how many request for one proxy
  variable DefaultMaxRequests 30
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
  variable StatusChecking 0

  variable Debug 0

  variable Log {
		INFO-FORCEBAN "force ban current proxy for tag"
		INFO-START "new getproxy request"
		INFO-STARTWAIT "make&vait selfcallback for non-interactive"
		INFO-STARTRETURN "return value"
		INFO-REACHMAXREQ "reach max requests for tag"
		INFO-NOCURRENT "no current proxy for tag"
		INFO-REACHTIMEOUT "remove used proxy by timeout"
		INFO-FOUNDNEW "found new proxy, suitable for tag"
		INFO-CALLBACK "start callback for request"
		INFO-STARTCHECK "try to check exists proxys"
		INFO-STOPCHECK "stop check proxy"
		INFO-STARTUPDATE "no proxy for tag, try to update proxy"
		INFO-UPDATEMOD "start update proxymod"
		ERROR-UPDATEMOD "error while update proxymod"
		INFO-REQSTART "req proxyupdate"
		ERROR-REQSTART "req proxyupdate error"
		INFO-REQCALLBACK "req proxyupdate callback"
		INFO-REQPARSESTART "req proxyupdate parse"
		ERROR-REQPARSESTART "req proxyupdate parse error"
		INFO-REQPARSEGOT "req proxyupdate parse, got proxys"
		INFO-UPDATESTOPED "no active update thread, empty proxylist status"
		INFO-CHKPROXY "test proxy"
		ERROR-CHKPROXY "error for proxy check"
		INFO-CHKCALLBACK "check proxy result"
		INFO-CHKCALLBACKOK "check proxy result: OK"
		INFO-CHKCALLBACKANON "check proxy result: ANON"
		ERROR-CHKCALLBACKANON "check proxy result: BAN - NOT anonymous"
		ERROR-CHKCALLBACKOK "check proxy result: BAN by status"
		INFO-RESETREQ "cancel request"
		ERROR-RESETREQ "error, request not found"
  }

  array set Requests [list]
  array set Tags [list]
  array set RequestCallback [list]

  proc log { id {detail {}} } {
    variable Debug
    variable Log
    if { !$Debug } return
    set str [dict get $Log $id]
    if { $detail ne "" } {
      append str ", detail: $detail"
    }
    puts "\[proxylist\] $str"
  }

  proc reset { req } {
    variable Requests
    if { [info exists Requests($req)] } {
      unset Requests($req)
      log "INFO-RESETREQ" $req
    } {
      log "ERROR-RESETREQ" $req
    }
  }

  proc forcebanproxy { tag } {
    variable Tags
    if { [info exists Tags([list $tag current])] } {
      lappend Tags([list $tag used]) [list [lindex $Tags([list $tag current]) 0 0] [lindex $Tags([list $tag current]) 2]]
      log "INFO-FORCEBAN" [list $tag [lindex $Tags([list $tag current]) 0]]
      unset Tags([list $tag current])
    }
  }

  proc configproxy { tag field {value {}} } {
    variable Tags
    variable DefaultMaxRequests
    variable DefaultTimeout
    if { $field ni {MaxRequests Timeout} } {
      return -code error "wrong field '$field', allowed: 'MaxRequests', 'Timeout'"
    }
    if { $value eq "" } {
      if { [array exists Tags] && [info exists Tags($field)] } {
        return $Tags($field)
      } {
        return [set Default$field]
      }
    }
    set Tags($field) $value
  }

  proc getproxy { { args {
    {-tag      string -default ""}
    {-callback string}
  }}} {
    variable ReqCounter
    variable Tags
    variable Requests
    variable RequestCallback
    variable DefaultMaxRequests
    variable DefaultTimeout

    set req [incr ReqCounter]
    log "INFO-START" $req
    set Requests($req) [dict create tag $opts(-tag)]
    foreach {k v} [list MaxRequests $DefaultMaxRequests Timeout $DefaultTimeout] {
	    if { ![info exists Tags([list $opts(-tag) $k])] } {
	      set Tags([list $opts(-tag) $k]) $v
	    }
	  }
    if { [info exists opts(-callback)] && $opts(-callback) ne "" } {
      dict set Requests($req) callback $opts(-callback)
      getproxy_
      return $req
    }
    log "INFO-STARTWAIT"
    dict set Requests($req) callback [list apply [list {req args} {
      variable RequestCallback
      set RequestCallback($req) $args
    } [namespace current]] $req]
    getproxy_
    vwait [namespace current]::RequestCallback($req)
    set result $RequestCallback($req)
    unset RequestCallback($req)
    log "INFO-STARTRETURN" $result
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
      #if current proxy for tag exists - then check for max requests
      if { [info exists Tags([list $tag current])] && $Tags([list $tag MaxRequests]) > 0 && [lindex $Tags([list $tag current]) 1] >= $Tags([list $tag MaxRequests]) } {
        lappend Tags([list $tag used]) [list [lindex $Tags([list $tag current]) 0 0] [lindex $Tags([list $tag current]) 2]]
        log "INFO-REACHMAXREQ" [list $tag [lindex $Tags([list $tag current]) 1] [lindex $Tags([list $tag current]) 0]]
        unset Tags([list $tag current])
      }
      if { ![info exists Tags([list $tag current])] } {
        
        log "INFO-NOCURRENT" [list $tag]
	      #cleanup used proxylist for tag
	      if { [info exists Tags([list $tag used])] } {
		      set newlist [list]
		      foreach proxy $Tags([list $tag used]) {
		        lassign $proxy host timestamp
		        if { ($timestamp + $Tags([list $tag Timeout])) >= [clock seconds] } {
		          lappend newlist [list $host $timestamp]
		        } {		          
		          log "INFO-REACHTIMEOUT" [list $host]
		        }
		      }
		      set Tags([list $tag used]) $newlist
		      unset newlist
		      unset -nocomplain proxy host timestamp
		    }
        #cleanup ProxylistOK
        if { ![info exists ProxylistOKcleanup] } {
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
          log "INFO-FOUNDNEW" [list $tag $proxy]
          break
	      }
	      unset -nocomplain proxy
	    }
	    if { [info exists Tags([list $tag current])] } {
	      set Tags([list $tag current]) [list [lindex $Tags([list $tag current]) 0] [expr { [lindex $Tags([list $tag current]) 1] + 1 }] [clock seconds]]
	      log "INFO-CALLBACK" [list $tag]
	      after 0 [linsert [dict get $Requests($req) callback] end ok {*}[lindex $Tags([list $tag current]) 0]]
	      unset Requests($req)
	    } {
        if { [llength $ProxylistRAW] || [llength $ProxylistCHK] } {
	 		    if { ![info exists start_check] } {
	 		      set NeedGoodProxy $NeedGoodProxyMAX
	          check
	          set start_check 1
	        }
        } {
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
    log "INFO-STARTUPDATE"
    foreach ns [namespace children [namespace current]] {
      if { [info commands ${ns}::updateproxy] ne "" } {
        if { [info exists ${ns}::Status] && [set ${ns}::Status] in {"update" "error"} } continue
        log "INFO-UPDATEMOD" [list $ns]
        if { [catch {${ns}::updateproxy} errmsg] } {
          log "ERROR-UPDATEMOD" [list $ns]
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
    log "INFO-REQSTART" [list [namespace tail $ns] $url]
    try {
      set token [::http::geturl $url {*}$arg -timeout 5000 \
                  -headers [list {Accept-Language} {ru-RU} {Accept-Encoding}	{gzip, deflate}] \
  			  	      -command [list apply {args { after 0 $args }} [namespace current]::httpreq_callback $ns]]  			  	      
    } on error { r o } {
      log "ERROR-REQSTART" [list [namespace tail $ns] "internal: $r"]
 	    catch { ::http::cleanup $token }
 	    tailcall httpreq_done $ns "error" ""
  	} finally {
	  	::http::config {*}$save
	    unset save
	  }
  }

  proc httpreq_callback { ns token } {
    log "INFO-REQCALLBACK" [list [namespace tail $ns] [::http::status $token] [::http::ncode $token]]
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
      log "INFO-REQPARSESTART" [list [namespace tail $ns]]
      if { [catch {${ns}::callback $data} result] } {
        log "ERROR-REQPARSESTART" [list [namespace tail $ns] $result]
      } {
        log "INFO-REQPARSEGOT" [list [namespace tail $ns] [llength $result]]
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
          return
        }
      }
    }
    log "INFO-UPDATESTOPED"
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
    variable StatusChecking
    if { $NeedGoodProxy <= 0 } {
      if { ![llength $ProxylistCHK] } {
		    log "INFO-STOPCHECK"
        set StatusChecking 0
      }
      return
    }
    if { !$StatusChecking } {
	    log "INFO-STARTCHECK"
      set StatusChecking 1
    }
    while { ([llength $ProxylistCHK] < $CheckThreadsMax) && [llength $ProxylistRAW] } {
      set proxy [lindex $ProxylistRAW 0]
      set ProxylistRAW [lreplace $ProxylistRAW 0 0]
      lappend ProxylistCHK $proxy
	    set save [::http::config]
      ::http::config -proxyhost [lindex $proxy 0]
      ::http::config -proxyport [lindex $proxy 1]
      log "INFO-CHKPROXY" [list $proxy]
      try {
	      set token [::http::geturl "http://www.find-ip.net/proxy-checker" -timeout 5000 \
                    -headers [list {Accept-Language} {ru-RU} {Accept-Encoding}	{gzip, deflate}] \
					  	      -command [list apply {args { after 0 $args }} [namespace current]::check_callback $proxy [clock milliseconds]]]
  	  } on error { r o } {
  	    log "ERROR-CHKPROXY" [list "internal - error $r"]
  	    lappend ProxylistBAN $proxy
  	    set ProxylistCHK [lreplace $ProxylistCHK end end]
  	  } finally {
	  	  ::http::config {*}$save
	      unset save
	    }
    }
    if { ![llength $ProxylistCHK] } {
	  	after 0 [namespace current]::getproxy_
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
    log "INFO-CHKCALLBACK" [list $proxy [::http::status $token] [::http::ncode $token]]
    if { [::http::status $token] eq "ok" && [::http::ncode $token] == 200 } {
      log "INFO-CHKCALLBACKOK" [list $proxy]
      if { [string first {No proxy is detected.} [::http::data $token]] != -1 } {
        log "INFO-CHKCALLBACKANON" [list $proxy]
        lappend ProxylistOK [list $proxy [clock seconds] [expr { [clock milliseconds] - $timestamp }]]
        set ProxylistOK [lsort -integer -increasing -index 2 $ProxylistOK]
        incr NeedGoodProxy -1
      } {
        log "ERROR-CHKCALLBACKANON" [list $proxy]
        lappend ProxylistBAN $proxy
      }
    } {
      log "ERROR-CHKCALLBACKOK" [list $proxy]
      lappend ProxylistBAN $proxy
    }
  	::http::cleanup $token
  	after 0 [namespace current]::check
  	after 0 [namespace current]::getproxy_
  }

}

package provide ckl::proxylist 1.0
