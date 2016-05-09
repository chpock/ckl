
namespace eval ::proxylist::proxysearcher-sourceforge-net {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://proxysearcher.sourceforge.net/Proxy%20List.php?type=http&filtered=true"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {<td>(\d+\.\d+\.\d+\.\d+):(\d+)</td><td>HighAnonymous</td>} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}
