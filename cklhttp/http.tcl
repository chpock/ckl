package require http
package require ckl::checkonline
package require ckl::proxylist
package require procarg
if { ![catch {package require tls}] } {
	::http::register https 443 [list apply {{args} { ::tls::socket -ssl3 false -ssl2 false -tls1 true -servername [lindex $args end-1] {*}[lrange $args 0 end-2] [lindex $args end-1] [lindex $args end] }}]
	::tls::init -tls1 1
}

namespace eval ::ckl::http {
  namespace import ::checkonline::checkonline
  namespace import ::proxylist::getproxy
  namespace import ::proxylist::configproxy
  namespace import ::proxylist::forcebanproxy
  namespace export geturl

  variable uid
  variable Debug 1

  variable Log {   
    INFO-INIT       "start geturl"
    INFO-CHKSTART   "start checkonline"
    INFO-CHKEND     "end checkonline"
    INFO-PRXSTART   "start getproxy"
    INFO-PRXEND     "end getproxy"
    INFO-HTTPSTART  "start http request"
    ERROR-HTTPSTART "http internal error"
    INFO-HTTPEND    "http request done"
    INFO-CALLBACK   "fire callback"
    INFO-CLEANUP    "cleanup token"
    INFO-RESET      "reset request"
  }   

  proc log { id {detail {}} } {
    variable Debug
    variable Log
    if { !$Debug } return
    set str [dict get $Log $id]
    if { $detail ne "" } {
      append str ", detail: $detail"
    }
    puts "\[ckl::http\] $str"
  }

  proc geturl { url { args {
		{0 string  -allowempty false}
    {-query       dict    -nodefault}
    {-callback    string  -nodefault -allowempty false}
    {-timeout     int     -default 60000}
    {-headers     dict    -nodefault}
    {-strict      boolean -default true}
    {-checkonline switch}
    {-proxytag    string  -nodefault}
    {-useragent   string  -nodefault}
    {-accept      string  -nodefault}
  }}} {
    log "INFO-INIT" $url
    variable uid
    set tokenname [namespace current]::token[incr uid]
    variable $tokenname
    upvar 0 $tokenname token
    set opts(url) $url
    if { ![info exists opts(-useragent)] } {
      set opts(-useragent) [::http::config -useragent]
    }
    if { ![info exists opts(-accept)] } {
      set opts(-accept) [::http::config -accept]
    }
    set opts(-proxyhost) ""
    set opts(-proxyport) ""
    set token(opts) [array get opts]
    if { $opts(-checkonline) } {
      log "INFO-CHKSTART"
      set token(state) "checkonline"
      set token(token) [checkonline -callback [list [namespace current]::geturl_checkonline $tokenname]]
    } {
      geturl_checkonline $tokenname
    }
    return $tokenname
  }

  proc geturl_checkonline { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    array set opts $token(opts)
    log "INFO-CHKEND"
    if { [info exists opts(-proxytag)] } {
      log "INFO-PRXSTART"
      set token(state) "getproxy"
      set token(token) [getproxy -callback [list [namespace current]::geturl_getproxy $tokenname] -tag $opts(-proxytag)]
    } {
      geturl_getproxy $tokenname
    }
  }

  proc geturl_getproxy { tokenname {s {}} {h {}} {p {}} } {
    variable $tokenname
    upvar 0 $tokenname token
    array set opts $token(opts)
    if { $s ne "" } {
      set opts(-proxyhost) $h
      set opts(-proxyport) $p
    }
    log "INFO-PRXEND"
    set cmd [list ::http::geturl $opts(url) -timeout $opts(-timeout) -strict $opts(-strict) \
      -command [list apply {args { after 0 $args }} [namespace current]::geturl_http $tokenname]]
    if { [info exists opts(-query)] } {
      lappend cmd -query [::http::formatQuery {*}$opts(-query)]
    }
    if { [info exists opts(-headers)] } {
      lappend cmd -headers $opts(-headers)
    }
    set token(state) "http"
    log "INFO-HTTPSTART"
    set save [::http::config]
    ::http::config -proxyhost $opts(-proxyhost)
    ::http::config -proxyport $opts(-proxyport)
    ::http::config -accept    $opts(-accept)
    ::http::config -useragent $opts(-useragent)
    try {
      set token(token) [{*}$cmd]
    } on error { r o } {
      log "ERROR-HTTPSTART" $r
      set token(state) "ierror"
      set token(error) $r
      geturl_callback $tokenname
    } finally {
  	  ::http::config {*}$save
    }
  }

  proc geturl_http { tokenname _ } {
    log "INFO-HTTPEND"
    geturl_callback $tokenname
  }

  proc geturl_callback { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    array set opts $token(opts)
    log "INFO-CALLBACK" $opts(-callback)
    after 0 [linsert $opts(-callback) end $tokenname]
  }

  proc ncode { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    if { $token(state) eq "http" } {
      tailcall ::http::ncode $token(token)
    } {
      return -code error "ncode is undefined with state $token(state)"
    }
  }

  proc data { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    if { $token(state) eq "http" } {
      tailcall ::http::data $token(token)
    } {
      return -code error "data is undefined with state $token(state)"
    }
  }

  proc status { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    if { $token(state) eq "http" } {
      tailcall ::http::status $token(token)
    } else {
      return $token(state)
    }
  }

  proc meta { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    if { $token(state) eq "http" } {
      tailcall ::http::meta $token(token)
    } {
      return -code error "meta is undefined with state $token(state)"
    }
  }

  proc error { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    if { $token(state) eq "http" } {
      tailcall ::http::error $token(token)
    } elseif { $token(state) eq "ierror" } {
      return $token(error)
    } {
      return -code error "error is undefined with state $token(state)"
    }
  }

  proc cleanup { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    log "INFO-CLEANUP"
    switch -- $token(state) {
      "http" {
        ::http::cleanup $token(token)
      }
      "checkonline" {
        ::checkonline::reset $token(token)
      }
    }
    unset $tokenname
  }

  proc reset { tokenname } {
    variable $tokenname
    upvar 0 $tokenname token
    log "INFO-RESET"
    switch -- $token(state) {
      "http" {
        tailcall ::http::reset $token(token)
      }
      "checkonline" {
        ::checkonline::reset $token(token)
	      set token(state) "reset"
  	    set token(error) "reset by request"
    	  geturl_callback $tokenname
      }
      "getproxy" {
        ::proxylist::reset $token(token)
	      set token(state) "reset"
  	    set token(error) "reset by request"
      }
      default {
        return -code error "can't reset from state '$token(state)'"
      }
    }
  }

}

package provide ckl::http 1.0
