# Negoto JSON API
This document defines the endpoints and the items returned from them.

The returned items will be described as Typescript type signatures.


## Basic types

```typescript
// An identifier for a certain resource.
type id = number;

// The time in seconds since January 1st, 1970 at 00:00.
type unix_time = number;

type url = string;

interface Board {
  id:   string;
  name: string;
}

interface File {
  filename: string;
  src:      url;
  thumb:    url;
  spoiler:  boolean;
}

interface Thread {
  id:      id;
  updated: unix_time;
  subject: string;
  count:   number;
  locked:  boolean;
  board:   string;
}

interface ThreadOp {
  id:      id;
  board:   string;
  updated: unix_time;
  subject: string;
  count:   number;
  locked:  boolean;
  name:    string;
  time:    unix_time;
  body:    string;
  files:   Array<File>;
}

interface Post {
  number: id;
  name:   string;
  time:   unix_time;
  body:   string;
  files:  Array<File>;
}

interface NewsItem {
  title:  string;
  author: string;
  time:   unix_time;
  body:   string;
}
```


## Board list

URL: `/Api/boards`

Returns: `Array<Board>`

Errors: none


## Board catalog

URL: `/Api/catalog/<id>`

Returns: `Array<ThreadOp>`

Errors:
* When the board doesn't exist, the endpoint will return a JSON string
  with the error message.


## Thread

Url: `/Api/thread/<id>`

Returns: `{ thread: Thread, posts: Array<Post> }`

Errors:
* When the thread pointed at doesn't exist, the endpoint will return a
  JSON string with the error message.


## News

Url: `/Api/news`

Returns: `Array<NewsItem>`

Errors: none


## Readme

Url: `/Api/readme`

Returns: `string`

Errors: none
