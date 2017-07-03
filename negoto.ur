fun main () =
  tags <- Data.allTags ();
  return <xml>
    <head>
      <title>negoto</title>
    </head>
    <body>
      <h1>Negoto</h1>

      Tag list
      <ul>
        {List.mapX (fn x => <xml><li>{[x.Nam]} - {[x.Slug]}</li></xml>) tags}
      </ul>
    </body>
  </xml>
