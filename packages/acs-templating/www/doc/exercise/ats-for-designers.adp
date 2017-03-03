
<property name="context">{/doc/acs-templating {ACS Templating}} {The ACS Templating System for Web Designers}</property>
<property name="doc(title)">The ACS Templating System for Web Designers</property>
<master>
<h2>The ACS Templating System for Web Designers</h2>
<strong>
<a href="../index">Templating System</a> : Templating
Exercise</strong>
<h3>Reading</h3>
<ul>
<li>ACS Templating System <a href="../index">documents</a>
</li><li>Templating System <a href="../../demo/">demo</a>
</li><li>Read beginning and end of <a href="http://acs40.arsdigita.com/doc/developer-guide/templates.html">Using
Templates in ACS 4</a>
</li>
</ul>
<h3>Sections</h3>
<ol>
<li><a href="#overview">Overview</a></li><li><a href="#exercises">Exercises</a></li>
</ol>
<h3><a name="overview" id="overview">Overview</a></h3>
<p>This series of exercises is meant as a learning tool for any web
graphic designer wanting or needing to understand how the ACS
Templating System, or ATS, works, and how to use it in building web
pages.</p>
<p>First, perhaps an explanation of what the templating system does
will help us understand how it works. An ATS template itself serves
as a reusable, unchanging framework that delivers dynamic data. The
advantage to this is something you probably already realize: you
need only build and edit a few pages to maintain a consistent
presentation style while accomodating numerous permutaions of
changing data.</p>
<p>This training module will teach largely by exercise and example,
but you should also refer regularly to the <a href="../index">ATS documents</a> provided and more specific
pointers will be given to help you out along the way.</p>
<p>Okay, let&#39;s get to the nitty gritty.</p>
<h3><a name="exercises" id="exercises">Exercises</a></h3>
<p>The basic building block of dynamic data in a template is the
onevalue variable. A <a href="../tags/variable">variable</a>
is simply a tag used in your <code>.adp</code> file that holds data
supplied by another source file; that source will probably be
another file of the same name with a <code>.tcl</code> extension.
Variable tags come in three basic formats, as <a href="../tags/list">lists</a>, <a href="../tags/multiple">multiples</a> and onevalues.</p>
<p>
<strong>Exercise 1: Onevalues, onelists, multilists and
multirows</strong><br>
(nestedlists, too?)</p>
<p>Let&#39;s first take a look at some list and variable tags in
action. Open up another browser and look at <a href="list-and-var-sample.txt">this page</a>, which is a text rendition
of the <code>/ats/doc/exercise/list-and-var-sample.tcl</code> page
we&#39;ll be sourcing our data from; at the top of the page
you&#39;ll find a block of commented text describing the variables
generated by this page, followed by the actual code itself. Now,
using your preferred text editor, open the file
<code>list-and-var-sample.adp</code> located in the same directory
and compare the html script that you see there with the final
user-viewed page, <code><a href="list-and-var-sample.acs">list-and-var-sample.acs</a></code>.
Almost every .acs page the user sees is supported by one .tcl file
which supplies the data to be shown, and one .adp file specifying
the format of it&#39;s presentation. Compare what you see in
<code>list-and-var-sample.acs</code> with its supporting .adp file
and make note of the textual and structural differences between the
two, specifically:</p>
<ul>
<li>
<a href="../tags/variable">variables</a> in the
<code>.adp</code> file are designated with "\@" markers,
like the <code>\@name\@</code> variable that litters the opening text
block of <code>list-and-var-sample.adp</code>; here,
<code>\@name\@</code> is used as a place-marker for the value set in
<code>list-and-var.sample.tcl</code>
</li><li>the variables within the <a href="../tags/multiple">&lt;multiple&gt;</a> tag, though only
appearing once in the .adp file, are cycled repeatedly to show
multiple sets of information when displayed in
<code>list-and-var-sample.acs</code>; example:
<blockquote><pre><code>    &lt;multiple name="<em>your_multirow</em>"&gt;
    &lt;tr&gt;&lt;td&gt;\@<em>your_multirow</em>.first_names\@ \@<em>your_multirow</em>.last_name\@ &lt;/td&gt; &lt;/tr&gt;
    &lt;/multiple&gt;
    </code></pre></blockquote>
The user will see one table row filled with a different
person&#39;s name for each row contained in the multirow
<code><em>your_multirow</em></code>.</li><li>multirow variables are identified with this format: \@&lt;name
of the multirow&gt;.&lt;name of a field in the multirow&gt;\@, and
can only be called within their respective
<code>&lt;multiple&gt;</code> tags</li>
</ul>
<p>You probably noticed some other funky looking tags, too, but
ignore those for now.</p>
<p>Now since the variable marker <code>\@name\@</code> is set in
<code>list-and-var-sample.tcl</code>, you can go ahead and edit
that file to replace "<code>(Your Name)</code>" with
whatever your name really is (be sure to leave the quotes); if you
wish,edit some of the other values to personalize the page.
You&#39;ll see your changes take effect upon saving the .tcl file
and reloading <code>list-and-var-sample.acs</code>. In general,
though, you should probably not be editing .tcl files unless you
have a pretty good sense of their innerworkings.</p>
<p>Okay, now go back to the web browser in which you are viewing
<code>list-and-var-sample.acs</code> and change the
".acs" extension to "<a href="list-and-var-sample.dat">.dat</a>". This page displays a view
of datasources generated in the .tcl file that can be used in your
.adp template (actually, the information is generated from
commented text parsed from the top of the .tcl file, so you can
view this information in either the .dat page or straight from the
.tcl file). Go ahead and make use of the datasource variables not
already included in the .adp file; specifically, change
<code>list-and-var-sample.adp</code> so that:</p>
<ul>
<li>your personal phone number information is included</li><li>each of your friends' names serves as a hyperlink that
allows the viewer to email your friend</li><li>a listing of recently watched movies and your reactions to them
follows after the information about your friends</li><li>also, note that the use of any variable tags referring to
variables not declared in the .tcl file will break the .acs
page</li>
</ul>
<p>Congratulations! You&#39;ve just created a personalized web page
describing friends you&#39;ve never met and movies you&#39;ve
possibly never seen.</p>
<p><strong>Exercise Two: &lt;if&gt; and &lt;else&gt;, the
conditional tags</strong></p>
<p>Dynamic data implies a changing page, and also changing
presentation. The <a href="../tags/if">&lt;if&gt;</a> and
&lt;else&gt; tags allow you to alter the format of your page to
accomodate data changes. The function of &lt;if&gt; is
straightforward enough: given a condition -- such as \@x\@ equals 5
-- all the text/html/dynamic data between the the opening and
closing &lt;if&gt; tags will be displayed if and only if \@x\@ does
in fact equal 5. A complete listing of currently supported
conditions and some brief explanatory notes can be found <a href="../tags/if">here</a>. Also, a few more things to keep in
mind:</p>
<ul>
<li>in Tcl all variables, even numbers, are stored as text strings
with quantitative values, so conditions like less than, greater
than, and (not) between can also be used with text to determine
alphabetical order: <em>a</em> &lt; <em>b</em> &lt; ... &lt;
<em>z</em>, lower-case letters are greater than upper-case, and
numbers less than letters. Example: "you" are greater
than "me", and "I" am less than
"you"</li><li>the "between" conditions checks inclusively, so
&lt;if 2 between 2 6&gt; will test true</li><li>
<code>&lt;if \@a\@ between \@b\@ \@c\@&gt;</code> requires that
<code>\@a\@</code> is greater than or equal to <code>\@b\@</code><em>and</em> less than or equal to <code>\@c\@</code>; so
<code>&lt;if \@x\@ between 4 2&gt;</code> will always test false</li><li>the "in" condition uses a regular expression check
(or will it? <font color="red">come back here and
revise</font>)</li>
</ul>
<p>Now, alter a few of the &lt;if&gt; tags in
<code>list-and-var-samle.adp</code> and add a few of your own.
Specifically, add one &lt;if&gt; and &lt;else&gt; combination so
that the friend description reads "likes chocolate" when
<code>likes_chocolate_p</code> is "t", "doesn&#39;t
like chocolate" when <code>likes_chocolate_p</code> is
"f", or "probably like chocolate" if
<code>likes_chocolate_p</code> is an empty string. Also, add one
&lt;if&gt;, and one &lt;if&gt; only, so that <em>a</em> is
appropriately changed to <em>an</em> for any 11-, 18- or 80- to
89-year olds.</p>
<p><strong>Exercise Three: The &lt;master&gt; and &lt;slave&gt;
tags -- a call to the dominatrix in you</strong></p>
<p>The <a href="../tags/master">&lt;master&gt;</a> and
<a href="../tags/slave">&lt;slave&gt;</a> tags allow you to
maintain a consistent style and format among pages without having
to edit each page individually. To get a sense of what these tags
do and how they work, go ahead and run through this short <a href="slave-sample.acs">demonstration</a>, and then use a text editor to
view the related .adp files. Also, read <a href="../guide/master">this discussion</a> on the use of master
pages.</p>
<p>One thing you may have noticed earlier about
<code>list-and-var-sample.adp</code> is that it lacks the standard
&lt;html&gt;, &lt;head&gt;, &lt;title&gt; and &lt;body&gt; tags.
This is because <code>list-and-var-sample.adp</code> is, as
indicated by the &lt;master&gt; tag at the top of the file, also a
slave section, contained within <code>master-sample.adp</code>.</p>
<p>Let me stress a few key points you might have already picked up
on from the demonstration and upon examining the .adp files, and
add a few pointers:</p>
<ul>
<li>the &lt;slave&gt; tag indicates where on the master page the
slave section is inserted</li><li>slave pages indicate the source of the master file with the
&lt;master&gt; tag, referring by the file name only, and not
including its ".adp" extension</li><li>as mentioned earlier, slave sections do not require
&lt;html&gt;, &lt;head&gt;, and &lt;body&gt; tags when contained
within a master tag already formatted for HTML</li><li>as the demonstration points out, pages are browsed at the .acs
page sharing the same file name as the slave, not master</li><li>the master page can be viewed at its own .acs page, but shows
nothing in place of the &lt;slave&gt; tag</li><li>you can have nested slave sections, that is, a slave section
within another slave</li><li>you <strong>cannot</strong> have two different slave sections
within the same master (go ahead and try adding an extra
&lt;slave&gt; tag to a master page to see what happens)</li><li>
<a href="../tags/property">&lt;property&gt;</a> tags are
used within a slave section to pass text, HTML and references to
local datasources up to the master page; these values are placed in
the master page in the same fashion as onevalues</li><li>data and HTML can be passed from a nested slave section to its
uber-master by using one &lt;property&gt; tag on each intermediate
page</li><li>if a variable set in the Tcl file of a master page shares the
same name as a variable declared within the slave section&#39;s
&lt;property&gt; tag, the master value overrides the slave&#39;s
(unless the Tcl code checks for pre-existing information)</li>
</ul>
<p>Now that the secrets of &lt;master&gt; and &lt;slave&gt; have
been revealed, it&#39;s time to put a little of your newfound
knowledge to use. Open up <a href="form-sample.acs"><code>form-sample.adp</code></a>, a standalone,
independently formatted html page, and enslave it to the mastery of
of your personal web page. It would also be nice if you were to
label the newly inserted form with some slave-specific title.</p>
<p>
<strong>Exercise Four: The functions of
&lt;formtemplate&gt;</strong><br>
</p>
<p>Creating forms with ATS can be as simple as inserting two tags
into a page. Try this: open <code>form-sample.adp</code> and add
the two following ATS tags:</p>
<blockquote><code><kbd><a href="../tags/formtemplate">&lt;formtemplate
id="add_entry"&gt;&lt;/formtemplate&gt;</a></kbd></code></blockquote>
<p>Save the page and reload it. You should see now see a big
baby-blue form block; this is the ATS default style for form
presentation. Aside from requiring no HTML code, the
&lt;formtemplate&gt; default has the added convenience of automated
entry validation with appropriate correction requests. Test this
out by trying to submit a form without including first or last name
or gender information.</p>
<p>However, if ever you wish to build a form according to the
mandates of your own taste, &lt;formtemplate&gt; also leaves you
this option. Manually stylizing forms with ATS requires you to
learn only two more tags, <a href="../tags/formwidget">&lt;formwidget&gt;</a> and <a href="../tags/formgroup">&lt;formgroup&gt;</a>. Browse through the
ATS <a href="../../demo">demo</a> for examples of
&lt;formwidget&gt; and &lt;formwidget&gt; usage. For the most part
&lt;formwidget&gt; should be used in most places you might have
used &lt;select&gt; or &lt;input&gt; in plain HTML, save for
&lt;input&gt; checkboxes and radio buttons, which should be
replaced with the &lt;formgroup&gt; tag. When working with ATS you
should probably refrain from using plain &lt;input&gt; and
&lt;select&gt; tags altogether.</p>
<p>You may have already noticed a few &lt;formwidget&gt; and
&lt;formgroup&gt; in use within the block of HTML and ATS text
commented out in <code>form-sample.adp</code>. Go ahead and put
that block of HTML/ATS code into action by removing the comment tag
wrapper and deleting the <code>&lt;/formtemplate&gt;</code> tag;
you should now see a hand-built version of the same form.</p>
<p>There are noticeable differences between the two form templates,
most obviously the lack of background color and a few missing entry
fields in the manually constructed one. Maybe not so noticeable is
the grouping of entry widgets into one HTML table row (check out
the <em>Name</em> field) and the multi-input combination of text
entry boxes and radio buttons for entering telephone number
information. Take a look at how the phone information entry section
is constructed in <code>form-sample.adp</code>. Note specifically:
&lt;formgroup&gt; is somewhat similar to the &lt;multiple&gt; tag
in that the block of ATS code contained within the
&lt;formgroup&gt; tags will be parsed into plain HTML once for each
&lt;formgroup&gt; value option.</p>
<p>Practice using &lt;formwidget&gt; and &lt;formgroup&gt; by
adding the missing entry fields manually into the form. Make free
use of any HTML properties to streamline the form to your liking.
If you can&#39;t remember what those fields were you can replace
the closing &lt;/formtemplate&gt; tag to recover the default
format, or make use of the .dat datasource page to view your
developer&#39;s description and comments about the form.</p>
<p>Also, try customizing your form&#39;s error response/correction
request text. You&#39;ll need to use the <a href="../tags/formerror">&lt;formerror&gt;</a> tag, an example of
which can be found under the gender formwidget.</p>
<p><strong>Exercise Five: more fun with multirows</strong></p>
<p>Now that you&#39;ve confidently added the conditional &lt;if&gt;
and &lt;else&gt; tags to your ATS toolbelt, it&#39;s time to put
those tools to good use in formatting multirow data. First, read
the <a href="../tags/multiple">docs</a> to learn about the
automatcally generated <code>\@<em>your_multirow</em>.rownum\@</code>
column, the <code>\@<em>your_multirow</em>:rowcount\@</code> onevalue
which contains the total number of rows contained in your multirow,
and the &lt;multiple&gt; <code>startrow</code> and
<code>maxrows</code> attributes. Possible point of confusion: the
variable <code>\@<em>your_multirow</em>:rowcount\@</code> is a
onevalue and not a column of the multirow
<code><em>your_multirow</em></code>, so it need not be used within
&lt;multiple&gt; tags and in many cases should not be used within
&lt;multiple&gt; tags. Why is this? (Take a look at how
<code>\@address:rowcount\@</code> is used.) Now make the following
improvements to the address book listing you found in
<code>form-sample.acs</code>:</p>
<ul>
<li>stripe the table with banded rows of alternating grey and
white, or some other color scheme of your preference</li><li>use the <code>startrow</code> attribute so that the address
book listing begins at a rownumber determined by the Tcl file code
(check the .dat page)</li><li>add navigation links to the address book so that users can move
forward or back between row listings, or jump to the beginning or
end of their address book</li><li style="list-style: none"><ul>
<li>each link should set the url variable that determines the first
row of the set to be displayed</li><li>the links should only appear when necessary, that is, a link
pointing towards the next set of rows should not appear if the user
is already viewing rows 1-5 of 5 total rows.</li>
</ul></li>
</ul>
<hr>
<address><a href="mailto:shuynh\@arsdgita.com">shuynh\@arsdigita.com</a></address>
<!-- hhmts start -->
Last modified: Fri Nov 17 10:14:44 EST 2000 <!-- hhmts end -->