# Disabled module
# Too many not working & not anon proxys

namespace eval ::proxylist::www-ip-adress-com {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://www.ip-adress.com/proxy_list/?k=time&d=desc"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {<a href=./proxy_list/(\d+\.\d+\.\d+\.\d+):(\d+)[^\d]} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}