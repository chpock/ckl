
namespace eval ::proxylist::free-proxy-list-net {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://free-proxy-list.net/"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {<tr><td>(\d+\.\d+\.\d+\.\d+)</td><td>(\d+)</td><td>} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}