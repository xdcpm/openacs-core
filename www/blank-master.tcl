# /www/master-default.tcl
#
# Set basic attributes and provide the logical defaults for variables that
# aren't provided by the slave page.
#
# Author: Kevin Scaldeferri (kevin@arsdigita.com)
# Creation Date: 14 Sept 2000
# $Id$
#

# fall back on defaults

if { [template::util::is_nil doc_type] } { 
    set doc_type {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}
}

if { [template::util::is_nil title] } { 
    set title [ad_conn instance_name]  
}

if { ![info exists header_stuff] } {
    set header_stuff {} 
}


# Attributes

template::multirow create attribute key value

# Pull out the package_id of the subsite closest to our current node
set pkg_id [site_node_closest_ancestor_package "acs-subsite"]

template::multirow append \
    attribute bgcolor [ad_parameter -package_id $pkg_id bgcolor   dummy "white"]
template::multirow append \
    attribute text    [ad_parameter -package_id $pkg_id textcolor dummy "black"]

if { [info exists prefer_text_only_p]
     && $prefer_text_only_p == "f"
     && [ad_graphics_site_available_p] } {
  template::multirow append attribute background \
    [ad_parameter -package_id $pkg_id background dummy "/graphics/bg.gif"]
}

if { ![template::util::is_nil focus] } {
    # Handle elements wohse name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        template::multirow append \
                attribute onload "javascript:acs_Focus('${form_name}', '${element_name}')"
    }
}

# Header links (stylesheets, javascript)
multirow create header_links rel type href media
multirow append header_links "stylesheet" "text/css" "/resources/acs-templating/lists.css" "all"
multirow append header_links "stylesheet" "text/css" "/resources/acs-templating/forms.css" "all"
multirow append header_links "stylesheet" "text/css" "/resources/acs-subsite/default-master.css" "all"

# Developer-support: We include that here, so that master template authors don't have to worry about it

if { [llength [namespace eval :: info procs ds_show_p]] == 1 } {
    set developer_support_p 1
} else {
    set developer_support_p 0
}

if { [llength [namespace eval :: info procs ds_link]] == 1 } {
     set ds_link [ds_link]
} else {
    set ds_link {}
}

set translator_mode_p [lang::util::translator_mode_p]
