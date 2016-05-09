# Disabled module
# Too many not working & not anon proxys
return

namespace eval ::proxylist::nordvpn-com {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "https://nordvpn.com/wp-admin/admin-ajax.php?[::http::formatQuery \
                        {searchParameters[0][name]} {proxy-country} {searchParameters[0][value]} {} \
                        {searchParameters[1][name]} {proxy-ports}   {searchParameters[1][value]} {} \
                        {searchParameters[2][name]} {http}          {searchParameters[2][value]} {on} \
                        {searchParameters[3][name]} {https}         {searchParameters[3][value]} {on} \
                        {offset} {25} {limit} {1000} {action} {getProxies}]"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {"ip":"(\d+\.\d+\.\d+\.\d+)","port":"(\d+)"} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}