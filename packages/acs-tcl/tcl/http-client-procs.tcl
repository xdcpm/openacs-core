ad_library {

    Procs for http client comunication

    @author Antonio Pisano
    @creation-date 2014-02-13
}


####################################
## New HTTP client implementation ##
####################################

namespace eval util {}
namespace eval util::http {}


ad_proc -private util::http::apis_not_cached {
} {
    Obtains implemented apis for http communication
} {
    set http  [list]
    set https [list]
    if {[util::which curl] ne ""} {
        lappend http  "curl"
        lappend https "curl"
    }
    if {[info commands ns_http] ne ""} {
        lappend http  "native"
    }
    if {[info commands ns_ssl] ne ""} {
        lappend https "native"
    }
    return [list $http $https]
}

ad_proc -private util::http::apis {
} {
    Obtains implemented apis for http communication
} {
    return [util_memoize [list util::http::apis_not_cached]]
}


#
## Procs common to both implementations
#

ad_proc -private util::http::get_channel_settings {
    content_type
} {
    Helper proc to get encoding based on content_type (From xotcl/tcl/http-client-procs)
} {
    # In the following, I realise a IANA/MIME charset resolution
    # scheme which is compliant with RFC 3023 which deals with
    # treating XML media types properly.
    #
    # see http://tools.ietf.org/html/rfc3023
    #
    # This makes the use of [ns_encodingfortype] obsolete as this
    # helper proc does not consider RFC 3023 at all. In the future,
    # RFC 3023 support should enter a revised [ns_encodingfortype],
    # for now, we fork.
    # 
    # The mappings between Tcl encoding names (as shown by [encoding
    # names]) and IANA/MIME charset names (i.e., names and aliases in
    # the sense of http://www.iana.org/assignments/character-sets) is
    # provided by ...
    # 
    # i. a static, built-in correspondence map: see nsd/encoding.c
    # ii. an extensible correspondence map (i.e., the ns/charsets
    # section in config.tcl).
    #
    # For mapping charset to encoding names, I use
    # [ns_encodingforcharset].
    #
    # Note, there are also alternatives for resolving IANA/MIME
    # charset names to Tcl encoding names, however, they all have
    # issues (non-extensibility from standard configuration sites,
    # incompleteness, redundant thread-local storing, scripted
    # implementation):
    # 1. tcllib/mime package: ::mime::reversemapencoding()
    # 2. tdom: tDOM::IANAEncoding2TclEncoding(); see lib/tdom.tcl

    #
    # RFC 3023 support (at least in my reading) demands the following
    # resolution order (see also Section 3.6 in RFC 3023), when
    # applied along with RFC 2616 (see especially Section 3.7.1 in RFC 2616)
    #
    # (A) Check for the "charset" parameter on certain (!) media types:
    # an explicitly stated, yet optional "charset" parameter is
    # permitted for all text/* media subtypes (RFC 2616) and selected
    # the XML media type classes listed by RFC 3023 (beyond the text/*
    # media type; e.g. "application/xml*", "*/*+xml", etc.).
    #
    # (B) If the "charset" is omitted, certain default values apply (!):
    #
    #    (B.1) RFC 3023 text/* registrations default to us-ascii (!),
    #    and not iso-8859-1 (overruling RFC 2616).
    #
    #   (B.2) RFC 3023 application/* and non-text "+xml" registrations
    #    are to be left untreated (in our context, no encoding
    #    filtering is to be applied -> "binary")
    #
    #   (B.3) RFC 2616 text/* registration (if not covered by B.1)
    #   default to iso-8859-1
    #
    # (C) If neither A or B apply (e.g., because an invalid charset
    # name was given to the charset parameter), we default to
    # "binary". This corresponds to the behaviour of
    # [ns_encodingfortype].  Also note, that the RFCs 3023 and 2616 do
    # not state any procedure when "invalid" charsets etc. are
    # identified. I assume, RFC-compliant clients have to ignore them
    # which means keep the channel in- and output unfiltered (encoding
    # = "binary"). This requires the client of the *HttpRequest* to
    # treat the data accordingly.
    #
    
    set enc ""
    if {[regexp {^text/.*$|^.*/xml.*$|^.*\+xml.*$} $content_type]} {
        # Case (A): Check for an explicitly provided charset parameter
        if {[regexp {;\s*charset\s*=([^;]*)} $content_type _ charset]} {
            set enc [ns_encodingforcharset [string trim $charset]]
        } 
        # Case (B.1)
        if {$enc eq "" && [regexp {^text/xml.*$|text/.*\+xml.*$} $content_type]} {
            set enc [ns_encodingforcharset us-ascii]
        } 

        # Case (B.3)
        if {$enc eq "" && [string match "text/*" $content_type]} {
            set enc [ns_encodingforcharset iso-8859-1]
        }   
    }
    # Cases (C) and (B.2) are covered by the [expr] below.
    set enc [expr {$enc eq ""?"binary":$enc}]
    
    return $enc
}

ad_proc util::http::get {
    -url 
    {-headers ""} 
    {-timeout 30}
    {-depth 0}
    {-max_depth 1}
    -force_ssl:boolean
    -gzip_response:boolean
    {-spool_file ""}
    {-preference {native curl}}
} {
    <p>
    Issue an http GET request to <code>url</code>.<br/>
    </p>
    
    <p>
    <tt>-headers</tt> specifies an ns_set of extra headers to send to the server when doing the request. 
    Some options exist that allow to avoid the need to specify headers manually, but headers will always take precedence over options.
    <p>
    
    <p>
    <tt>-gzip_response_p</tt> informs the server that we are capable of receiving gzipped responses.
    If server complies to our indication, the result will be automatically decompressed.
    </p>
    
    <p>
    <tt>-force_ssl_p</tt> specifies wether we want to use SSL despite the url being in http:// form.
    Default behavior is to use SSL on https:// urls only.
    </p>
    
    <p>
    <tt>-spool_file</tt> enables file spooling of the request on the file specified. It is useful when we expect large responses from the server.
    </p>
    
    <p>
    <tt>-preference decides which available implementation prefer in respective order. Choice is between 'native', based on ns_ api, available for Naviserver 
    only and giving the best performances and 'curl', which wraps the command line utility (available on every system with curl installed).
    </p>
    
    Returns the data in array get form with array elements page, status, and modified.
} {
    return [util::http::request \
                -url             $url \
                -method          GET \
                -force_ssl=$force_ssl_p \
                -gzip_response=$gzip_response_p \
                -headers         $headers \
                -timeout         $timeout \
                -max_depth       $max_depth \
                -depth           $depth \
                -spool_file      $spool_file \
                -preference      $preference]
}

ad_proc util::http::post {
    -url 
    {-files {}}
    -base64:boolean
    {-formvars ""}
    {-body ""}
    {-headers ""}
    {-timeout 30}
    {-depth 0}
    {-max_depth 1}
    -force_ssl:boolean
    -multipart:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    {-spool_file ""}
    {-preference {native curl}}
} {
    <p>
    Implement client-side HTTP POST request.
    </p>
    
    <p>
    <tt>-body</tt> is the payload for the request and will be passed as is (useful for many purposes, such as webDav). 
    A convenient way to specify form variables through this argument is passing a string obtained by <code>export_vars -url</code>.
    </p>
    
    <p>
    File upload can be specified using actual files on the filesystem or binary strings of data using the <code>-files</code> parameter.
    <code>-files</code> must be a list of array-lists in the form returned by <code>array get</code>.<br/>
    Keys of <code>-files</code> parameter are:
    <ul>
    <li>data: binary data to be sent. If set, has precedence on 'file' key</li>
    <li>file: path for the actual file on filesystem</li>
    <li>filename: name the form will receive for this file</li>
    <li>fieldname: name the field this file will be sent as</li>
    <li>mime_type: mime_type the form will receive for this file</li>
    </ul>
    If 'filename' is missing and an actual file is being sent, it will be set as the same name as the file.<br/>
    If 'mime_type' is missing, it will be guessed from 'filename'. If result is */* or an empty mime_type, 'application/octet-stream' will be used<br/>
    If <code>-base64</code> flag is set, files will be base64 encoded (useful for some kind of form).
    </p>    
    <p>
    Other form variables can be passes in<code>-formvars</code> easily by the use of <code>export_vars -url</code> and will be translated 
    for the proper type of form. URL variables, as with GET requests, are also sent, but an error is thrown if URL variables conflict with those specified
    in other ways.
    </p>
    
    <p>
    Default behavior is to build payload as an 'application/x-www-form-urlencoded' payload if no files are specified,
    and 'multipart/form-data' otherwise. If <code>-multipart</code> flag is set, format will be forced to multipart.
    </p>

    <p>
    <tt>-headers</tt> specifies an ns_set of extra headers to send to the server when doing the request. 
    Some options exist that allow to avoid the need to specify headers manually, but headers will always take precedence over options.
    </p>

    <p>
    <tt>-gzip_request_p</tt> informs the server that we are sending data in gzip format. Data will be automatically compressed.
    Notice that not all servers can treat gzipped requests properly, and in such cases response will likely be an error.
    </p>

    <p>
    <tt>-gzip_response_p</tt> informs the server that we are capable of receiving gzipped responses.
    If server complies to our indication, the result will be automatically decompressed.
    </p>
    
    <p>
    <tt>-force_ssl_p</tt> specifies wether we want to use SSL despite the url being in http:// form.
    Default behavior is to use SSL on https:// urls only.
    </p>
    
    <p>
    <tt>-spool_file</tt> enables file spooling of the request on the file specified. It is useful when we expect large responses from the server.
    </p>
    
    <p>
    <tt>-post_redirect</tt> decides what happens when we are POSTing and server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2 states that method 
    should not change when 301 or 302 are returned, and that GET should be used on a 303 response, but most HTTP clients fail in respecting this and switch 
    to a GET request independently. This options forces this kinds of redirect to conserve their original method.
    </p>
    
    <p>
    <tt>-max_depth</tt> is the maximum number of redirects the proc is allowed to follow. Be aware that when following redirects, unless it is a code 303
    redirect, url and POST urlencoded variables will be sent again to the redirected host. Multipart variables won't be sent again. 
    Sending to the redirected host can be dangerous, if such host is not trusted or uses a lower level of secutiry. The default behavior is to not follow
    redirects.
    </p>
    
    <p>
    <tt>-preference decides which available implementation prefer in respective order. Choice is between 'native', based on ns_ api, available for Naviserver 
    only and giving the best performances and 'curl', which wraps the command line utility (available on every system with curl installed).
    </p>
} {
    set this_proc [lindex [info level 0] 0]
    
    # Retrieve variables sent by the URL...
    set vars [lindex [split $url ?] 1]
    foreach var [split $vars &] {
        set var [split $var =]
        set key [lindex $var 0]
        set urlvars($key) 1
    }
    
    # Check wether we don't have multiple variable definition in url and payload
    foreach var [split $formvars &] {
        set var [split $var =]
        set key [lindex $var 0]
        if {[info exists urlvars($key)]} {
            return -code error "${this_proc}:  Variable '$key' already specified as url variable"
        }
    }
    
    if {$headers eq ""} {
        set headers [ns_set create headers]
    }
    
    # If required from headers, force a multipart form
    set req_content_type [ns_set iget $headers "content-type"]
    if {$req_content_type ne ""} {
        set multipart_p [string match -nocase "*multipart/form-data*" $req_content_type]
        # avoid duplicated headers
        ns_set idelkey $headers "Content-type"
    }

    ## Construction of the payload
    # By user choice, or because we have files, this will be a 'multipart/form-data' payload...
    if {$multipart_p || $files ne [list]} {
        
        set boundary [ns_sha1 [list [clock clicks -milliseconds] [clock seconds]]]
        ns_set put $headers "Content-type" "multipart/form-data; boundary=$boundary"
        
        set payload {}
        
        # Transform files into binaries
        foreach file $files {
            array set f $file
            
            if {![info exists f(data)]} {
                if {![info exists f(file)]} {
                    return -code error "${this_proc}:  No file or binary data specified"
                }
                if {![file exists $f(file)]} {
                    return -code error "${this_proc}:  Error reading file: $f(file) not found"
                }
                if {![file readable $f(file)]} {
                    return -code error "${this_proc}:  Error reading file: $f(file) permission denied"
                }

                set fp [open $f(file)]
                fconfigure $fp -translation binary
                set f(data) [read $fp]
                close $fp

                if {![info exists f(filename)]} {
                    set f(filename) [file tail $f(file)]
                }
            }
            
            foreach key {data filename fieldname} {
                if {![info exists f($key)]} {
                    return -code error "${this_proc}:  '$key' missing for binary data"
                }
            }
            
            # Check that we don't already have this var specified in the url
            if {[info exists urlvars($f(fieldname))]} {
                return -code error "${this_proc}:  file field '$f(fieldname)' already specified as url variable"
            }
            # Track form variables sent as files
            set filevars($f(fieldname)) 1
            
            if {![info exists f(mime_type)]} {
                set f(mime_type) [ns_guesstype $f(filename)]
                if {$f(mime_type) in {"*/*" ""}} {
                    set f(mime_type) "application/octet-stream"
                }
            }

            if {$base64_p} {
                set f(data) [base64::encode $f(data)]
                set transfer_encoding base64
            } else {
                set transfer_encoding binary
            }

            append payload --$boundary \
                \r\n \
                "Content-Disposition: form-data; " \
                "name=\"$f(fieldname)\"; filename=\"$f(filename)\"" \
                \r\n \
                "Content-Type: $f(mime_type)" \
                \r\n \
                "Content-transfer-encoding: $transfer_encoding" \
                \r\n \
                \r\n \
                $f(data) \
                \r\n
            
        } ; unset files

        # Translate urlencoded vars into multipart variables
        foreach formvar [split $formvars &] {
            set formvar [split $formvar  =]
            set key [lindex $formvar 0]
            set val [join [lrange $formvar 1 end] =]
            
            if {[info exists filevars($key)]} {
                return -code error "${this_proc}:  Variable '$key' already specified as file variable"
            }

            append payload --$boundary \
                \r\n \
                "Content-Disposition: form-data; name=\"$key\"" \
                \r\n \
                \r\n \
                $val \
                \r\n
            
        } ; unset formvars

        append payload --$boundary-- \r\n
        
        # ...otherwise this will be an 'application/x-www-form-urlencoded' payload
    } else {
        ns_set put $headers "Content-type" "application/x-www-form-urlencoded"
        set payload $formvars; unset formvars
    }
    
    # Body will be appended as is to the payload
    append payload $body; unset body
    
    return [util::http::request -method POST \
                -body            $payload \
                -headers         $headers \
                -url             $url \
                -timeout         $timeout \
                -depth           $depth \
                -max_depth       $max_depth \
                -force_ssl=$force_ssl_p \
                -gzip_request=$gzip_request_p \
                -gzip_response=$gzip_response_p \
                -post_redirect=$post_redirect_p \
                -spool_file      $spool_file \
                -preference      $preference]
}

ad_proc util::http::request {
    -url 
    -method
    {-headers ""} 
    {-body ""}
    {-timeout 30} 
    {-depth 0}
    {-max_depth 1}
    -force_ssl:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    {-spool_file ""}
    {-preference {native curl}}
} {
    <p>
    Issue an HTTP request either GET or POST to the url specified.
    </p>
    
    <p>
    <tt>-headers</tt> specifies an ns_set of extra headers to send to the server when doing the request. 
    Some options exist that allow to avoid the need to specify headers manually, but headers will always take precedence over options.
    <p>
    
    <p>
    <tt>-body</tt> is the payload for the request and will be passed as is (useful for many purposes, such as webDav). 
    A convenient way to specify form variables for POST payloads through this argument is passing a string obtained by <code>export_vars -url</code>.
    </p>

    <p>
    <tt>-gzip_request_p</tt> informs the server that we are sending data in gzip format. Data will be automatically compressed.
    Notice that not all servers can treat gzipped requests properly, and in such cases response will likely be an error.
    </p>
    
    <p>
    <tt>-gzip_response_p</tt> informs the server that we are capable of receiving gzipped responses.
    If server complies to our indication, the result will be automatically decompressed.
    </p>
    
    <p>
    <tt>-force_ssl_p</tt> specifies wether we want to use SSL despite the url being in http:// form. Default behavior is to use SSL on https:// urls only.
    </p>
    
    <p>
    <tt>-spool_file</tt> enables file spooling of the request on the file specified. It is useful when we expect large responses from the server.
    </p>
    
    <p>
    <tt>-post_redirect</tt> decides what happens when we are POSTing and server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2 states that method 
    should not change when 301 or 302 are returned, and that GET should be used on a 303 response, but most HTTP clients fail in respecting this and switch 
    to a GET request independently. This options forces this kinds of redirect to conserve their original method. Notice that, as from RFC, a 303 redirect
    won't send again any data to the server, as specification says we can assume variables to have been received.
    </p>
    
    <p>
    <tt>-max_depth</tt> is the maximum number of redirects the proc is allowed to follow. Be aware that when following redirects, unless it is a code 303
    redirect, url and POST urlencoded variables will be sent again to the redirected host. Multipart variables won't be sent again. 
    Sending to the redirected host can be dangerous, if such host is not trusted or uses a lower level of secutiry. The default behavior is to not follow
    redirects.
    </p>
    
    <p>
    <tt>-preference decides which available implementation prefer in respective order. Choice is between 'native', based on ns_ api, available for Naviserver 
    only and giving the best performances and 'curl', which wraps the command line utility (available on every system with curl installed).
    </p>
} {
    set this_proc [lindex [info level 0] 0]
    
    if {$force_ssl_p || [string match "https://*" $url]} {
        set apis [lindex [apis] 1]
    } else {
        set apis [lindex [apis] 0]
    }
    
    foreach p $preference {
       if {$p in $apis} {
          set impl $p; break
       }
    }
    if {![info exists impl]} {
        return -code error "${this_proc}:  HTTP client functionalities for this protocol are not available with current system configuration."
    }
    
    return [util::http::${impl}::request -method $method \
                -body            $body \
                -headers         $headers \
                -url             $url \
                -timeout         $timeout \
                -depth           $depth \
                -max_depth       $max_depth \
                -force_ssl=$force_ssl_p \
                -gzip_request=$gzip_request_p \
                -gzip_response=$gzip_response_p \
                -post_redirect=$post_redirect_p \
                -spool_file      $spool_file]
}


#
## Native Naviserver implementation
#

namespace eval util::http::native {}

ad_proc -private util::http::native::request {
    -url 
    -method
    {-headers ""} 
    {-body ""}
    {-timeout 30} 
    {-depth 0}
    {-max_depth 1}
    -force_ssl:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    {-spool_file ""}
} {
    <p>
    Issue an HTTP request either GET or POST to the url specified.
    </p>
    
    <p>
    <tt>-headers</tt> specifies an ns_set of extra headers to send to the server when doing the request. 
    Some options exist that allow to avoid the need to specify headers manually, but headers will always take precedence over options.
    <p>
    
    <p>
    <tt>-body</tt> is the payload for the request and will be passed as is (useful for many purposes, such as webDav). 
    A convenient way to specify form variables for POST payloads through this argument is passing a string obtained by <code>export_vars -url</code>.
    </p>

    <p>
    <tt>-gzip_request_p</tt> informs the server that we are sending data in gzip format. Data will be automatically compressed.
    Notice that not all servers can treat gzipped requests properly, and in such cases response will likely be an error.
    </p>
    
    <p>
    <tt>-gzip_response_p</tt> informs the server that we are capable of receiving gzipped responses.
    If server complies to our indication, the result will be automatically decompressed.
    </p>
    
    <p>
    <tt>-force_ssl_p</tt> specifies wether we want to use SSL despite the url being in http:// form. Default behavior is to use SSL on https:// urls only.
    </p>
    
    <p>
    <tt>-spool_file</tt> enables file spooling of the request on the file specified. It is useful when we expect large responses from the server.
    </p>
    
    <p>
    <tt>-post_redirect</tt> decides what happens when we are POSTing and server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2 states that method 
    should not change when 301 or 302 are returned, and that GET should be used on a 303 response, but most HTTP clients fail in respecting this and switch 
    to a GET request independently. This options forces this kinds of redirect to conserve their original method. Notice that, as from RFC, a 303 redirect
    won't send again any data to the server, as specification says we can assume variables to have been received.
    </p>
    
    <p>
    <tt>-max_depth</tt> is the maximum number of redirects the proc is allowed to follow. Be aware that when following redirects, unless it is a code 303
    redirect, url and POST urlencoded variables will be sent again to the redirected host. Multipart variables won't be sent again. 
    Sending to the redirected host can be dangerous, if such host is not trusted or uses a lower level of secutiry. The default behavior is to not follow
    redirects.
    </p>
    <br/>
    This is the native implementation based on Naviserver HTTP api
} {
    set this_proc [lindex [info level 0] 0]
    
    if {![regexp "^(https|http)://*" $url]} {
        return -code error "${this_proc}:  Invalid url:  $url"
    }
    
    if {[incr depth] > $max_depth} {
        return -code error "${this_proc}:  Recursive redirection:  $url"
    }
    
    # Check wether we will use ssl or not
    if {$force_ssl_p || [string match "https://*" $url]} {
        if {[info commands ns_ssl] eq ""} {
            return -code error "${this_proc}:  SSL not enabled"
        }
        set http_api "ns_ssl"
    } else {
        set http_api "ns_http"
    }
    
    if {$headers eq ""} {
        set headers [ns_set create headers]
    }
    
    # Determine wether we want to gzip the request.
    # Servers uncapable of treating such requests will likely throw an error...
    set req_content_encoding [ns_set iget $headers "content-encoding"]
    if {$req_content_encoding ne ""} {
         set gzip_request_p [string match "*gzip*" $req_content_encoding]
    } elseif {$gzip_request_p} {
         ns_set put $headers "Content-Encoding" "gzip"
    }
    
    # See if we want the response to be gzipped by headers or options
    # Server can decide to ignore this and serve the encoding he desires.
    # I also say to server that whatever he can give me will do, in case.
    set req_accept_encoding [ns_set iget $headers "accept-encoding"]
    if {$req_accept_encoding ne ""} {
        set gzip_response_p [string match "*gzip*" $req_accept_encoding]
    } elseif {$gzip_response_p} {
        ns_set put $headers "Accept-Encoding" "gzip, */*"
    }
    
    # zlib is mandatory when requiring compression
    if {$gzip_request_p || $gzip_response_p} {
        if {[info commands zlib] eq ""} {
            return -code error "${this_proc}:  zlib support not enabled"
        }
    }
    
    ## Encoding of the request
    
    # Any conversion or encoding of the payload 
    # should happen only at the first redirect
    if {$depth == 1} {
        set content_type [ns_set iget $headers "content-type"]
        if {$content_type eq ""} {
            set content_type "text/plain; charset=[ns_config ns/parameters OutputCharset iso-8859-1]"
        }
        
        set enc [util::http::get_channel_settings $content_type]
        if {$enc ne "binary"} {
            set body [encoding convertto $enc $body]
        }
        
        if {$gzip_request_p} {
            set body [zlib gzip $body]
        }
    }
    
    
    ## Issuing of the request
    
    # Spooling to files is disabled for now
    set spool_file ""
    
    set queue_cmd [list $http_api queue -timeout $timeout -method $method -headers $headers]
    if {$body ne ""} {
        lappend queue_cmd -body $body
    }
    if {$spool_file ne ""} {
        lappend queue_cmd -spoolsize 0 -file $spool_file
        set page "${this_proc}: response spooled to '$spool_file'"
    }
    lappend queue_cmd $url
    
    set resp_headers [ns_set create resp_headers]
    set wait_cmd [list $http_api wait -headers $resp_headers -status status]
    if {$spool_file eq ""} {
        lappend wait_cmd -result page
    }
    
    if {$gzip_response_p} {
        # Naviserver since 4.99.6 can decompress response transparently
        if {[ns_info patchlevel] >= 4.99.6} {
            append wait_cmd { -decompress}
        }
    }
    
    # Queue call to the url and wait for response
    {*}$wait_cmd [{*}$queue_cmd]

    # Get values from response headers, then remove them
    set content_type     [ns_set iget $resp_headers content-type]
    set content_encoding [ns_set iget $resp_headers content-encoding]
    set location         [ns_set iget $resp_headers location]
    set last_modified    [ns_set iget $resp_headers last-modified]
    ns_set free $resp_headers
    
    
    ## Redirection management ##
    
    # Simple case: page had not been modified.
    if {$status == 304} {
        set page ""
        # Other kinds of redirection...
    } elseif {[string match "3??" $status] && $location ne ""} {
        # Decide by which method follow the redirect
        if {$method eq "POST"} {
            if {$status in {301 302 303} && !$post_redirect_p} {
                set method "GET"
            }
        }
        
        set urlvars [list]
        
        # ...retrieve redirect location variables...
        set locvars [lindex [split $location ?] 1]
        if {$locvars ne ""} {
            lappend urlvars $locvars
        }
        
        lappend urlvars [lindex [split $url ?] 1]
        
        # If we have POST payload and we are following by GET, put the payload into url vars.
        if {$method eq "GET" && $body ne ""} {
            set req_content_type [ns_set iget $headers "content-type"]
            set multipart_p [string match -nocase "*multipart/form-data*" $req_content_type]
            # I decided to don't translate into urlvars a multipart payload.
            # This makes sense if we think that in a multipart payload we have
            # many informations, such as mime_type, which cannot be put into url.
            # Receiving a GET redirect after a POST is very common, so I won't throw an error
            if {!$multipart_p} {
                if {$gzip_request_p} {
                    set body [zlib gunzip $body]
                }
                lappend urlvars $body
            }
        }
        
        # Unite all variables into location URL
        set urlvars [join $urlvars &]
        
        if {$urlvars ne ""} {
            set location ${location}?${urlvars}
        }
        
        if {$method eq "GET"} {
            return [$this_proc -url $location
                    -method          GET
                    -force_ssl=$force_ssl_p 
                    -gzip_response=$gzip_response_p 
                    -post_redirect=$post_redirect_p
                    -headers         $headers 
                    -timeout         $timeout 
                    -depth           $depth 
                    -spool_file      $spool_file]
        } else {
            return [$this_proc -method POST \
                        -body            $body \
                        -headers         $headers \
                        -url             $location \
                        -timeout         $timeout \
                        -depth           $depth \
                        -force_ssl=$force_ssl_p \
                        -gzip_request=$gzip_request_p \
                        -gzip_response=$gzip_response_p \
                        -post_redirect=$post_redirect_p \
                        -spool_file      $spool_file]
        }
    }
    
    
    ## Decoding of the response
    
    # If response was compressed and our Naviserver
    # is prior 4.99.6, we have to decompress on our own.
    if {$content_encoding eq "gzip"} {
      if {[ns_info patchlevel] < 4.99.6} {
        if {$spool_file eq "" } {
            set page [zlib gunzip $page]
        }
      }
    }
    
    # Translate into proper encoding
    set enc [util::http::get_channel_settings $content_type]
    if {$enc ne "binary"} {
        set page [encoding convertfrom $enc $page]
    }
    
    
    return [list \
                page     $page \
                status   $status \
                modified $last_modified]
}


#
## Curl wrapper implementation
#

namespace eval util::http::curl {}

ad_proc -private util::http::curl::request {
    -url 
    -method
    {-headers ""} 
    {-body ""}
    {-timeout 30} 
    {-depth 0}
    {-max_depth 1}
    -force_ssl:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    {-spool_file ""}
} {
    <p>
    Issue an HTTP request either GET or POST to the url specified.
    </p>
    
    <p>
    <tt>-headers</tt> specifies an ns_set of extra headers to send to the server when doing the request. 
    Some options exist that allow to avoid the need to specify headers manually, but headers will always take precedence over options.
    <p>
    
    <p>
    <tt>-body</tt> is the payload for the request and will be passed as is (useful for many purposes, such as webDav). 
    A convenient way to specify form variables for POST payloads through this argument is passing a string obtained by <code>export_vars -url</code>.
    </p>

    <p>
    <tt>-gzip_request_p</tt> informs the server that we are sending data in gzip format. Data will be automatically compressed.
    Notice that not all servers can treat gzipped requests properly, and in such cases response will likely be an error.
    </p>
    
    <p>
    <tt>-gzip_response_p</tt> informs the server that we are capable of receiving gzipped responses.
    If server complies to our indication, the result will be automatically decompressed.
    </p>
    
    <p>
    <tt>-force_ssl_p</tt> is ignored when using curl http client implementation and is only kept for cross compatibility
    </p>
    
    <p>
    <tt>-spool_file</tt> enables file spooling of the request on the file specified. It is useful when we expect large responses from the server.
    </p>
    
    <p>
    <tt>-post_redirect</tt> decides what happens when we are POSTing and server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2 states that method 
    should not change when 301 or 302 are returned, and that GET should be used on a 303 response, but most HTTP clients fail in respecting this and switch 
    to a GET request independently. This options forces this kinds of redirect to conserve their original method.
    </p>
    
    <p>
    <tt>-max_depth</tt> is the maximum number of redirects the proc is allowed to follow. Be aware that when following redirects, unless it is a code 303
    redirect, url and POST urlencoded variables will be sent again to the redirected host. Multipart variables won't be sent again. 
    Sending to the redirected host can be dangerous, if such host is not trusted or uses a lower level of secutiry. The default behavior is to not follow
    redirects.
    </p>
    <br/>
    This is the curl wrapper implementation, used on Aolserver and when ssl native capabilities are not available.
} {
    set this_proc [lindex [info level 0] 0]
    
    if {![regexp "^(https|http)://*" $url]} {
        return -code error "${this_proc}:  Invalid url:  $url"
    }
    
    if {$headers eq ""} {
        set headers [ns_set create headers]
    }
    
    # Determine wether we want to gzip the request.
    # Default is no, can't know wether the server accepts it.
    # We could at the http api level (TODO?)
    set req_content_encoding [ns_set iget $headers "content-encoding"]
    if {$req_content_encoding ne ""} {
        set gzip_request_p [string match "*gzip*" $req_content_encoding]
    } elseif {$gzip_request_p} {
        ns_set put $headers "Content-Encoding" "gzip"
    }
    
    # Curls accepts gzip by default, so if gzip response is not required 
    # we have to ask explicitly for a plain text enconding
    set req_accept_encoding [ns_set iget $headers "accept-encoding"]
    if {$req_accept_encoding ne ""} {
        set gzip_response_p [string match "*gzip*" $req_accept_encoding]
    } elseif {!$gzip_response_p} {
        ns_set put $headers "Accept-Encoding" "utf-8"
    }
    
    # zlib is mandatory when compressing the input
    if {$gzip_request_p} {
        if {[info commands zlib] eq ""} {
            return -code error "${this_proc}:  zlib support not enabled"
        }
    }
    
    ## Encoding of the request
    
    set content_type [ns_set iget $headers "content-type"]
    if {$content_type eq ""} {
        set content_type "text/plain; charset=[ns_config ns/parameters OutputCharset iso-8859-1]"
    }
    
    set enc [util::http::get_channel_settings $content_type]
    if {$enc ne "binary"} {
        set body [encoding convertto $enc $body]
    }
    
    if {$gzip_request_p} {
        set body [zlib gzip $body]
    }
    
    ## Issuing of the request
    
    # Spooling to files is disabled for now
    set spool_file ""
    
    set cmd [list exec curl -s]
    
    if {$spool_file ne ""} {
        lappend cmd -o $spool_file
    }
    
    if {$timeout ne ""} {
        lappend cmd --connect-timeout $timeout
    }
    
    # Set redirection up to max_depth
    if {$max_depth ne ""} {
        lappend cmd -L --max-redirs $max_depth
    }
    
    if {$method eq "GET"} {
        lappend cmd -G
    }
    
    # If required, we'll follow POST request redirections by GET
    if {!$post_redirect_p} {
        lappend cmd --post301 --post302 --post303
    }
    
    # Curl can decompress response transparently
    if {$gzip_response_p} {
        lappend cmd --compressed
    }
    
    lappend cmd --data-binary $body
    
    # Return response code toghether with webpage
    lappend cmd -w " %\{http_code\}"
    
    # Add headers to the command line
    foreach {key value} [ns_set array $headers] {
        if {$value eq ""} {
            set value ";"
        } else {
            set value ": $value"
        }
        set header "${key}${value}"
        lappend cmd -H "$header"
    }
    
    # Dump response headers into a tempfile to get them
    set resp_headers_tmpfile [ns_tmpnam]
    lappend cmd -D $resp_headers_tmpfile
    lappend cmd $url
     
    set response [{*}$cmd]
     
    # Parse headers from dump file
    set resp_headers [ns_set create resp_headers]
    set rfd [open $resp_headers_tmpfile r]
    while {[gets $rfd line] >= 0} {
        set line [split $line ":"]
        set key [lindex $line 0]
        set value [join [lrange $line 1 end] ":"]
        ns_set put $resp_headers $key $value
    }
    close $rfd
    file delete $resp_headers_tmpfile
    
    # Get values from response headers, then remove them
    set content_type     [ns_set iget $resp_headers content-type]
    set last_modified    [ns_set iget $resp_headers last-modified]
    ns_set free $resp_headers
    
    set status [string range $response end-2 end]
    set page   [string range $response 0 end-3]
    
    if {$spool_file ne ""} {
        set page "${this_proc}: response spooled to '$spool_file'"
    }
    
    # Translate into proper encoding
    set enc [util::http::get_channel_settings $content_type]
    if {$enc ne "binary"} {
        set page [encoding convertfrom $enc $page]
    }
    
    return [list \
                page     $page \
                status   $status \
                modified $last_modified]
}



#########################
## Deprecated HTTP api ##
#########################

ad_proc -deprecated -public ad_httpget {
    -url 
    {-headers ""} 
    {-timeout 30}
    {-depth 0}
} {
    Just like ns_httpget, but first headers is an ns_set of
    headers to send during the fetch.

    ad_httpget also makes use of Conditional GETs (if called with a 
                                                   Last-Modified header).

    Returns the data in array get form with array elements page status modified.
} {
    ns_log debug "Getting {$url} {$headers} {$timeout} {$depth}"

    if {[incr depth] > 10} {
        return -code error "ad_httpget:  Recursive redirection:  $url"
    }

    lassign [ns_httpopen GET $url $headers $timeout] rfd wfd headers
    close $wfd

    set response [ns_set name $headers]
    set status [lindex $response 1]
    set last_modified [ns_set iget $headers last-modified]

    if {$status == 302 || $status == 301} {
        set location [ns_set iget $headers location]
        if {$location ne ""} { 
            ns_set free $headers
            close $rfd
            return [ad_httpget -url $location -timeout $timeout -depth $depth]
        }
    } elseif { $status == 304 } {
        # The requested variant has not been modified since the time specified
        # A conditional get didn't return anything.  return an empty page and 
        set page {}

        ns_set free $headers
        close $rfd
    } else { 
        set length [ns_set iget $headers content-length]
        if { $length eq "" } {set length -1}

        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd

        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    }

    # order matters here since we depend on page content 
    # being element 1 in this list in util_httpget 
    return [list page $page \
                status $status \
                modified $last_modified]
}

ad_proc -deprecated -public util_httpget {
    url {headers ""} {timeout 30} {depth 0}
} {
    util_httpget simply calls ad_httpget which also returns 
    status and last_modfied
    
    @see ad_httpget
} {
    return [lindex [ad_httpget -url $url -headers $headers -timeout $timeout -depth $depth] 1]
}

# httppost; give it a URL and a string with formvars, and it 
# returns the page as a Tcl string
# formvars are the posted variables in the following form: 
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

ad_proc -deprecated -public util_httppost {url formvars {timeout 30} {depth 0} {http_referer ""}} {
    Returns the result of POSTing to another Web server or -1 if there is an error or timeout.  
    formvars should be in the form \"arg1=value1&arg2=value2\".  
    <p> 
    post is encoded as application/x-www-form-urlencoded.  See util_http_file_upload
    for file uploads via post (encoded multipart/form-data).
    <p> 
    @see util_http_file_upload
} {
    if { [catch {
        if {[incr depth] > 10} {
            return -code error "util_httppost:  Recursive redirection:  $url"
        }
        set http [util_httpopen POST $url "" $timeout $http_referer]
        set rfd [lindex $http 0]
        set wfd [lindex $http 1]

        #headers necesary for a post and the form variables

        _ns_http_puts $timeout $wfd "Content-type: application/x-www-form-urlencoded \r"
        _ns_http_puts $timeout $wfd "Content-length: [string length $formvars]\r"
        _ns_http_puts $timeout $wfd \r
        _ns_http_puts $timeout $wfd "$formvars\r"
        flush $wfd
        close $wfd

        set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
        while 1 {
            set line [_ns_http_gets $timeout $rfd]
            if { $line eq "" } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        if {$status == 302} {
            set location [ns_set iget $headers location]
            if {$location ne ""} {
                ns_set free $headers
                close $rfd
                return [util_httpget $location {}  $timeout $depth]
            }
        }
        set length [ns_set iget $headers content-length]
        if { "" eq $length } {set length -1}
        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd
        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    } errmgs ] } {return -1}
    return $page
}

# system by Tracy Adams (teadams@arsdigita.com) to permit AOLserver to POST 
# to another Web server; sort of like ns_httpget

ad_proc -deprecated -public util_httpopen {
    method 
    url 
    {rqset ""} 
    {timeout 30} 
    {http_referer ""}
} { 
    Like ns_httpopen but works for POST as well; called by util_httppost
} { 
    
    if { ![string match "http://*" $url] } {
        return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
    }
    set url [split $url /]
    set hp [split [lindex $url 2] :]
    set host [lindex $hp 0]
    set port [lindex $hp 1]
    if { [string match $port ""] } {set port 80}
    set uri /[join [lrange $url 3 end] /]
    set fds [ns_sockopen -nonblock $host $port]
    set rfd [lindex $fds 0]
    set wfd [lindex $fds 1]
    if { [catch {
        _ns_http_puts $timeout $wfd "$method $uri HTTP/1.0\r"
        _ns_http_puts $timeout $wfd "Host: $host\r"
        if {$rqset ne ""} {
            for {set i 0} {$i < [ns_set size $rqset]} {incr i} {
                _ns_http_puts $timeout $wfd \
                    "[ns_set key $rqset $i]: [ns_set value $rqset $i]\r"
            }
        } else {
            _ns_http_puts $timeout $wfd \
                "Accept: */*\r"

            _ns_http_puts $timeout $wfd "User-Agent: Mozilla/1.01 \[en\] (Win95; I)\r"    
            _ns_http_puts $timeout $wfd "Referer: $http_referer \r"    
        }

    } errMsg] } {
        #close $wfd
        #close $rfd
        if { [info exists rpset] } {ns_set free $rpset}
        return -1
    }
    return [list $rfd $wfd ""]
    
}

ad_proc -deprecated -public util_http_file_upload { -file -data -binary:boolean -filename 
    -name {-mime_type */*} {-mode formvars} 
    {-rqset ""} url {formvars {}} {timeout 30} 
    {depth 10} {http_referer ""}
} {
    Implement client-side HTTP file uploads as multipart/form-data as per 
    RFC 1867.
    <p>

    Similar to <a href="proc-view?proc=util_httppost">util_httppost</a>, 
    but enhanced to be able to upload a file as <tt>multipart/form-data</tt>.  
    Also useful for posting to forms that require their input to be encoded 
    as <tt>multipart/form-data</tt> instead of as 
    <tt>application/x-www-form-urlencoded</tt>.

    <p>

    The switches <tt>-file /path/to/file</tt> and <tt>-data $raw_data</tt>
    are mutually exclusive.  You can specify one or the other, but not
    both.  NOTE: it is perfectly valid to not specify either, in which
    case no file is uploaded, but form variables are encoded using
    <tt>multipart/form-data</tt> instead of the usual encoding (as
                                                                noted aboved).

    <p>

    If you specify either <tt>-file</tt> or <tt>-data</tt> you 
    <strong>must</strong> supply a value for <tt>-name</tt>, which is
    the name of the <tt>&lt;INPUT TYPE="file" NAME="..."&gt;</tt> form
    tag.

    <p>

    Specify the <tt>-binary</tt> switch if the file (or data) needs
    to be base-64 encoded.  Not all servers seem to be able to handle
    this.  (For example, http://mol-stage.usps.com/mml.adp, which
            expects to receive an XML file doesn't seem to grok any kind of
            Content-Transfer-Encoding.)

    <p>

    If you specify <tt>-file</tt> then <tt>-filename</tt> is optional
    (it can be infered from the name of the file).  However, if you
    specify <tt>-data</tt> then it is mandatory.

    <p>

    If <tt>-mime_type</tt> is not specified then <tt>ns_guesstype</tt>
    is used to try and find a mime type based on the <i>filename</i>.  
    If <tt>ns_guesstype</tt> returns <tt>*/*</tt> the generic value
    of <tt>application/octet-stream</tt> will be used.
    
    <p>

    Any form variables may be specified in one of four formats:
    <ul>
    <li><tt>array</tt> (list of key value pairs like what [array get] returns)
    <li><tt>formvars</tt> (list of url encoded formvars, i.e. foo=bar&x=1)
    <li><tt>ns_set</tt> (an ns_set containing key/value pairs)
    <li><tt>vars</tt> (a list of tcl vars to grab from the calling enviroment)
    </ul>

    <p>

    <tt>-rqset</tt> specifies an ns_set of extra headers to send to
    the server when doing the POST.

    <p>

    timeout, depth, and http_referer are optional, and are included
    as optional positional variables in the same order they are used
    in <tt>util_httppost</tt>.  NOTE: <tt>util_http_file_upload</tt> does
    not (currently) follow any redirects, so depth is superfulous.

    @author Michael A. Cleverly (michael@cleverly.com)
    @creation-date 3 September 2002
} {

    # sanity checks on switches given
    if {$mode ni {formvars array ns_set vars}} {
        error "Invalid mode \"$mode\"; should be one of: formvars,\
            array, ns_set, vars"
    }
    
    if {[info exists file] && [info exists data]} {
        error "Both -file and -data are mutually exclusive; can't use both"
    }

    if {[info exists file]} {
        if {![file exists $file]} {
            error "Error reading file: $file not found"
        }

        if {![file readable $file]} {
            error "Error reading file: $file permission denied"
        }

        set fp [open $file]
        fconfigure $fp -translation binary
        set data [read $fp]
        close $fp

        if {![info exists filename]} {
            set filename [file tail $file]
        }

        if {$mime_type eq "*/*" || $mime_type eq ""} {
            set mime_type [ns_guesstype $file]
        }
    }

    set boundary [ns_sha1 [list [clock clicks -milliseconds] [clock seconds]]]
    set payload {}

    if {[info exists data] && [string length $data]} {
        if {![info exists name]} {
            error "Cannot upload file without specifing form variable -name"
        }
        
        if {![info exists filename]} {
            error "Cannot upload file without specifing -filename"
        }
        
        if {$mime_type eq "*/*" || $mime_type eq ""} {
            set mime_type [ns_guesstype $filename]
            
            if {$mime_type eq "*/*" || $mime_type eq ""} {
                set mime_type application/octet-stream
            }
        }

        if {$binary_p} {
            set data [base64::encode base64]
            set transfer_encoding base64
        } else {
            set transfer_encoding binary
        }

        append payload --$boundary \
            \r\n \
            "Content-Disposition: form-data; " \
            "name=\"$name\"; filename=\"$filename\"" \
            \r\n \
            "Content-Type: $mime_type" \
            \r\n \
            "Content-transfer-encoding: $transfer_encoding" \
            \r\n \
            \r\n \
            $data \
            \r\n
    }


    set variables [list]
    switch -- $mode {
        array {
            set variables $formvars 
        }

        formvars {
            foreach formvar [split $formvars &] {
                set formvar [split $formvar  =]
                set key [lindex $formvar 0]
                set val [join [lrange $formvar 1 end] =]
                lappend variables $key $val
            }
        }

        ns_set {
            for {set i 0} {$i < [ns_set size $formvars]} {incr i} {
                set key [ns_set key $formvars $i]
                set val [ns_set value $formvars $i]
                lappend variables $key $val
            }
        }

        vars {
            foreach key $formvars {
                upvar 1 $key val
                lappend variables $key $val
            }
        }
    }

    foreach {key val} $variables {
        append payload --$boundary \
            \r\n \
            "Content-Disposition: form-data; name=\"$key\"" \
            \r\n \
            \r\n \
            $val \
            \r\n
    }

    append payload --$boundary-- \r\n

    if { [catch {
        if {[incr depth -1] <= 0} {
            return -code error "util_http_file_upload:\
                Recursive redirection: $url"
        }

        lassign [util_httpopen POST $url $rqset $timeout $http_referer] rfd wfd 

        _ns_http_puts $timeout $wfd \
            "Content-type: multipart/form-data; boundary=$boundary\r"
        _ns_http_puts $timeout $wfd "Content-length: [string length $payload]\r"
        _ns_http_puts $timeout $wfd \r
        _ns_http_puts $timeout $wfd "$payload\r"
        flush $wfd
        close $wfd
        
        set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
        while 1 {
            set line [_ns_http_gets $timeout $rfd]
            if { $line eq "" } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        set length [ns_set iget $headers content-length]
        if { "" eq $length } { set length -1 }
        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]

        ns_set free $headers
        close $rfd

        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    } errmsg] } {
        if {[info exists wfd] && $wfd in [file channels]} {
            close $wfd
        }

        if {[info exists rfd] && $rfd in [file channels]} {
            close $rfd
        }

        set page -1
    }
    
    return $page
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End: