# https module

namespace eval ::proxylist::hidester-com {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "https://hidester.com/proxydata/php/data.php?mykey=data&offset=0&limit=100&orderBy=latest_check&sortOrder=DESC&country=&port=&type=3&anonymity=1&ping=1&gproxy=2"
  }

  proc callback { data } {
    set result [list]
 	  foreach {- host port} [regexp -all -inline -nocase {IP.:.(\d+\.\d+\.\d+\.\d+).,.PORT.:(\d+),} $data] {
 	    lappend result [list $host $port]
 	  }
    return $result
  }

}
