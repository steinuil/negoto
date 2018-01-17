# Negoto JSON API
This document defines the endpoints and the items returned from them.

The returned items will be described as Typescript type signatures.


## Basic types

```typescript
// An ID is an integer > 0.
type id = number;

// The hex md5 checksum of a file.
type checksum = string;

// The time in seconds since January 1st, 1970 at 00:00.
type unix_time = number;

interface Board {
  name: string;
  slug: string;
}

interface File {
  hash: checksum;
  name: string;
  mimetype: string;
  spoiler: boolean;
}

interface Thread {
  id: id;
  updated: unix_time;
  subject: string;
  count: int;
  locked: boolean;
  boards: Array<string>;
}

interface ThreadOp {
  id: id;
  updated: unix_time;
  subject: string;
  count: int;
  locked: boolean;
  boards: Array<string>;
  name: string;
  time: unix_time;
  body: string;
  files: Array<string>;
}

interface Post {
  id: number;
  thread: int;
  name: string;
  time: unix_time;
  body: string;
  files: Array<string>
}

interface NewsItem {
  title: string;
  author: string;
  time: unix_time;
  body: string;
}

interface Readme {
  body: string;
  updated: unix_time;
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

Returns: `Readme`

Errors: none
