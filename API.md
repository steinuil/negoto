# Negoto JSON API
This document defines the endpoints and the items returned from them.

The returned items will be described as Typescript type signatures.


## Basic types

```typescript
// An ID is an integer > 0.
type id = number;

// The ?? checksum of a file.
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
  extension: string;
  spoiler: boolean;
}

interface Thread {
  id: id;
  updated: unix_time;
  subject: string;
  locked: boolean;
  boards: Array<string>;
}

interface ThreadOp {
  id: id;
  updated: unix_time;
  subject: string;
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
```


## Board list

URL: `/Api/boards`

Returns: `Array<Board>`


## Board catalog

URL: `/Api/catalog/<id>`

Returns: `Array<ThreadOp>`

When the board doesn't exist, the endpoint will return an empty array.


## Thread

Url: `/Api/thread/<id>`

Returns: `{ thread: Thread, posts: Array<Post> }`

When the thread pointed at doesn't exist, the endpoints will return `null`.
