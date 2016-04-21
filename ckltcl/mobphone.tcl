
package provide ckl::mobphone 1.0

package require procarg

namespace eval ::ckl {
 	namespace export parse_phones
 	namespace export parse_imeis

  variable extract_mobile_phones_re {(?x)
		(?:\+?
		  (?:\m|\()38[\s\-]{0,3}\(?|
		  (?:\m|\()8[\s\-]{0,3}\(?|
		  \([\s\-]{0,3}|
		  \m
		)
		(
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d\d[\s\-]*\d\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d\d[\s\-]*\d\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d\d\d[\s\-]*\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d[\s\-]*\d\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d\d[\s\-]*\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d\d\d[\s\-]*\d)|
		  (?:0\s{0,3}\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d[\s\-]*\d\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d\d[\s\-]*\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d\d[\s\-]*\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]?\d\d[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d[\s\-]*\d\d)|
		  (?:0\s{0,3}\(?[1-9]\d[\s\-]?\d\d[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d[\s\-]*\d\d)
		)
		(?!\d)}

  variable extract_mobile_phones_re2 {(?x)
		(?:\+?
		  (?:\m|\()38[\s\-]{0,3}\(?0\s{0,3}|
		  (?:\m|\()8[\s\-]{0,3}\(?0\s{0,3}|
		  \([\s\-]{0,3}0\s{0,3}|
		  \m0\s{0,3}|
		  \m
		)
		(
		  (?:\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d\d[\s\-]*\d\d\d)|
		  (?:\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d\d[\s\-]*\d\d\d)|
		  (?:\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d\d\d[\s\-]*\d\d)|
		  (?:\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d[\s\-]*\d\d\d)|
		  (?:\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d\d[\s\-]*\d\d)|
		  (?:\(?[1-9]\d[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d\d\d[\s\-]*\d)|
		  (?:\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d[\s\-]*\d\d\d)|
		  (?:\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d\d[\s\-]*\d\d)|
		  (?:\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d\d[\s\-]*\d\d)|
		  (?:\(?[1-9]\d\(?\d\)?[\s\-]{0,3}\)?[\s\-]*\d\d\d[\s\-]*\d\d\d)|
		  (?:\(?[1-9]\d[\s\-]?\d\d[\s\-]{0,3}\)?[\s\-]*\d[\s\-]*\d\d[\s\-]*\d\d)|
		  (?:\(?[1-9]\d[\s\-]?\d\d[\s\-]{0,3}\)?[\s\-]*\d\d[\s\-]*\d[\s\-]*\d\d)
		)
		(?!\d)}

	variable extract_mobile_imeis_re {(?x)
		(?:
		  \m
		)
		(
		  \d{15}
		)
		(?!\d)}

	proc parse_imeis { text {args {
	  {-noextract switch}
	  {-indices   switch}
	  {-imeis     switch}
	  {-nocrc     switch}
	}} } {
	  variable extract_mobile_imeis_re

	  set imeilist  [list]
	  set cleantext ""
	  set offset    0
	  if { $opts(-imeis) } {
	    set opts(-noextract) 1
	  }

	  while { [regexp -indices $extract_mobile_imeis_re $text matchall matchimei] } {
	    set imei ""
	    foreach char [split [string range $text {*}$matchimei] {}] {
	      if { [string match {[0-9]} $char] } {
	        append imei $char
	      }
	    }
	    if { $opts(-indices) } {
	      lappend imeilist [list [expr { [lindex $matchall 0] + $offset }] [expr { [lindex $matchall 1] + $offset }]]
	      incr offset [lindex $matchall 1]
	      incr offset
	      set text [string range $text [lindex $matchall 1]+1 end]
	    } {
	      if { $opts(-nocrc) } {
	        set imei [string replace $imei end end 0]
	      }
	      lappend imeilist $imei
	      if { $opts(-noextract) } {
	        append cleantext [string range $text 0 [lindex $matchall 1]]
	        set text [string range $text [lindex $matchall 1]+1 end]
	      } {
	        append cleantext [expr { [string length $cleantext]?{ }:{} }][string trimright [string range $text 0 [lindex $matchall 0]-1]]
	        set text [string trimleft [string range $text [lindex $matchall 1]+1 end]]
	      }
	    }
	  }

	  if { $opts(-imeis) } {
	    return [lsort -unique $imeilist]
	  } elseif { $opts(-indices) } {
	    return $imeilist
	  } {
	    return [list $cleantext$text [lsort -unique $imeilist]]
	  }

	}

	proc parse_phones { text {args {
	  {-noextract switch}
	  {-indices   switch}
	  {-phones    switch}
	  {-shortcode boolean -default 0}
	}} } {
	  variable extract_mobile_phones_re
	  variable extract_mobile_phones_re2

	  set phonelist [list]
	  set cleantext ""
	  set offset    0
	  if { $opts(-phones) } {
	    set opts(-noextract) 1
	  }

	  while { ($opts(-shortcode) && [regexp -indices $extract_mobile_phones_re2 $text matchall matchphone]) || (!$opts(-shortcode) && [regexp -indices $extract_mobile_phones_re $text matchall matchphone]) } {
	    set phone ""
	    foreach char [split [string range $text {*}$matchphone] {}] {
	      if { [string match {[0-9]} $char] } {
	        append phone $char
	      }
	    }
	    if { $opts(-indices) } {
	      lappend phonelist [list [expr { [lindex $matchall 0] + $offset }] [expr { [lindex $matchall 1] + $offset }]]
	      incr offset [lindex $matchall 1]
	      incr offset
		    set text [string range $text [lindex $matchall 1]+1 end]
	    } {
	      if { $opts(-shortcode) && [string length $phone] == 9 } {
	        lappend phonelist "380$phone"
	      } {
			    lappend phonelist "38$phone"
			  }
	    	if { $opts(-noextract) } {
		      append cleantext [string range $text 0 [lindex $matchall 1]]
			    set text [string range $text [lindex $matchall 1]+1 end]
		    } {
			    append cleantext [expr { [string length $cleantext]?{ }:{} }][string trimright [string range $text 0 [lindex $matchall 0]-1]]
		  	  set text [string trimleft [string range $text [lindex $matchall 1]+1 end]]
		    }
		  }
	  }

	  if { $opts(-phones)  } {
	    return [lsort -unique $phonelist]
	  } elseif { $opts(-indices) } {
	    return $phonelist
	  } {
		  return [list $cleantext$text [lsort -unique $phonelist]]
		}

	}

}

namespace import ::ckl::parse_phones
namespace import ::ckl::parse_imeis
