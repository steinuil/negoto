table admins :
  { Nam : string }


table newsItems :
  { Title   : string
  , Author  : string
  , Time    : time
  , Body    : string }


fun layout (body' : xbody) : transaction page =
  return <xml>
    <head>
      <title>Admin</title>
    </head>
    <body>{body'}</body>
  </xml>


fun boards () =
  layout <xml>
  </xml>


val news =
  queryL1 (SELECT * FROM newsItems)
