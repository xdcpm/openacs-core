<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<h2>@page_title@</h2>

<if @success_p@ false>
  <p>Unfortunately, we had some errors. Please check your server error log or contact your system administrator. </p>
</if>
<else>
  <p> Done installing packages. </p>

  <p>
    <strong>&raquo;</strong> <a href="../server-restart">Click here to restart your server now</a>
  </p>
</else>

