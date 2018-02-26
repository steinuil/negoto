-- At least one theme and a default theme are required
-- for the program to work correctly.

PRAGMA foreign_keys=TRUE;

-- @Fixme these should be the md5 hashes of the files. We should generate
-- this file as part of the build process.
INSERT INTO uw_File_Css_files VALUES
("yotsuba.css", "text/css"),
("yotsuba-b.css", "text/css");


INSERT INTO uw_File_Css_handles VALUES
("yotsuba.css", -1),
("yotsuba-b.css", 0);


INSERT INTO uw_Layout_themes VALUES
("Yotsuba", "/static/css/yotsuba.css", -1, "#FFD6AE"),
("Yotsuba B", "/static/css/yotsuba-b.css", 0, "#D0D5E7");


INSERT INTO uw_KeyVal_store VALUES
("defaultTheme", -1);


INSERT INTO uw_Data_boards VALUES
("test", "Test board");


INSERT INTO uw_Admin_affLinks VALUES
("https://github.com/steinuil/negoto", "source")
