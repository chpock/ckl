
namespace eval ::proxylist::spys-ru {
  namespace import ::proxylist::httpreq

  variable Status

  proc updateproxy { } {
    httpreq "http://spys.ru/en/http-proxy-list/" -query [::http::formatQuery xpp 3 xf1 1 xf2 0 xf4 0]
  }

  proc callback { data } {
    set result [list]
    if { [regexp {<script type="text/javascript">((?:(?:[\w\d]+)=(?:[\w\d^]+);)+)</script>} $data -> vallist] } {
      foreach xval [split $vallist "\;"] {
        if { $xval eq "" } continue
        lassign [split $xval =] k v
        lassign [split $v ^] v1 v2
        if { $v2 eq "" } {
          dict set mkey $k $v1
        } {
          if { [dict exists $mkey $v1] } { set v1 [dict get $mkey $v1] }
          if { [dict exists $mkey $v2] } { set v2 [dict get $mkey $v2] }
          dict set mkey $k [expr { $v1 ^ $v2 }]
        }
      }
      foreach {- host xport} [regexp -all -inline -nocase {<font class=[^>]+?>(\d+?\.\d+?\.\d+?\.\d+?)<script type=.text/javascript.>document.write\(.<font class=spy2>:<\\/font>.\+(.+?)\)</script>} $data] {
        set port ""
        foreach xport [split $xport +] {
          set xport [split [string trim $xport {()}] ^]
          append port [expr { [dict get $mkey [lindex $xport 0]] ^ [dict get $mkey [lindex $xport 1]] }]
        }
	 	    lappend result [list $host $port]
      }
    }
    return $result
  }

}