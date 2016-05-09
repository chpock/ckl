
namespace eval ::proxylist::hideme-ru {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://hideme.ru/proxy-list/?type=hs&anon=4"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {<td class=tdl>(\d+\.\d+\.\d+\.\d+)</td><td>(\d+)</td>} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}