#!/bin/sh
set -uf

HANDLES_TABLE=uw_File_handle_Ids
CSS_FILES_TABLE=uw_File_Css_files
CSS_HANDLES_TABLE=uw_File_Css_handles
THEMES_TABLE=uw_Layout_themes
KV_TABLE=uw_KeyVal_store
BOARDS_TABLE=uw_Data_boards
ADMINS_TABLE=uw_Account_admins

DB_FILE=

die() {
  echo "$1" 1>&2
  exit 1
}

usage() {
  die "Usage: $0 -d <negoto.db> <command> <args>

Commands:
  add-theme <name> <file> <color>
  add-board <id> <name>
  add-admin <name> owner|admin|moderator"
}

next_css_handle() {
  sqlite3 "$DB_FILE" <<EOF
PRAGMA foreign_keys=TRUE;

INSERT INTO $HANDLES_TABLE VALUES (NULL);
SELECT id FROM $HANDLES_TABLE;
DELETE FROM $HANDLES_TABLE;
EOF
}

file_md5() {
  md5sum "$1" | cut -d ' ' -f 1
}

add_theme() {
  set -e

  name=$1
  file=$2
  color=$3

  hash=$(file_md5 "$file")
  handle=$(next_css_handle)

  sqlite3 "$DB_FILE" <<EOF
PRAGMA foreign_keys=TRUE;

INSERT INTO $CSS_FILES_TABLE VALUES ('$hash', 'text/css');
INSERT INTO $CSS_HANDLES_TABLE VALUES ('$hash', $handle);
INSERT INTO $THEMES_TABLE VALUES ('$name', '/static/css/$hash.css', $handle, '$color');

INSERT INTO $KV_TABLE VALUES ('defaultTheme', $handle) ON CONFLICT DO NOTHING;
EOF
  echo "Created theme '$name' with hash $hash"
}

add_board() {
  set -e

  id=$1
  name=$2

  sqlite3 "$DB_FILE" <<EOF
PRAGMA foreign_keys=TRUE;

INSERT INTO $BOARDS_TABLE VALUES ('$id', '$name');
EOF
  echo "Created board /$id/ - $name"
}

add_admin() {
  set -e

  name=$1
  role=$2
  password_hash='$2b$10$pZl/2fqRmnP.LCmE8K22/.MO29m64l/jRmUjpsYEF0IlO.kRSKHsm'

  role_id=

  case $role in
    owner)     role_id=2 ;;
    admin)     role_id=1 ;;
    moderator) role_id=0 ;;
    *) die "Invalid role: $role" ;;
  esac

  sqlite3 "$DB_FILE" <<EOF
PRAGMA foreign_keys=TRUE;

INSERT INTO $ADMINS_TABLE VALUES ('$name', $role_id, '$password_hash');
EOF
  echo "Created admin '$name' with role '$role' and default password 'password'"
}

getopts 'f:' f
case $f in
  f) DB_FILE=$OPTARG ;;
esac

if [ -z "$DB_FILE" ]; then
  usage
fi
shift; shift

if [ -z "$*" ]; then
  usage
fi

subcmd=$1
shift

case $subcmd in
  add-theme)
    if [ $# -ne 3 ]; then usage; fi
    add_theme "$1" "$2" "$3"
    ;;
  add-board)
    if [ $# -ne 2 ]; then usage; fi
    add_board "$1" "$2"
    ;;
  add-admin)
    if [ $# -ne 2 ]; then usage; fi
    add_admin "$1" "$2"
    ;;
  *)
    usage
    ;;
esac
