# Disabled module
# Too many not working proxys
return

namespace eval ::proxylist::www-prime-speed-ru {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://www.prime-speed.ru/proxy/free-proxy-list/anon-elite-proxy.php"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {\s(\d+\.\d+\.\d+\.\d+):(\d+)} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}
