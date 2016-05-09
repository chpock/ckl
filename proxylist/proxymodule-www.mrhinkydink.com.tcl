# Disabled module
# Too many not working proxys
return

namespace eval ::proxylist::www-mrhinkydink-com {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://www.mrhinkydink.com/proxies.htm"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {<tr[^>]*>\s*<td>(\d+\.\d+\.\d+\.\d+)</td>\s*<td>(\d+)</td>\s*<td>} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}