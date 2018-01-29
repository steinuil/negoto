-- At least one theme and a default theme are required
-- for the program to work correctly.
INSERT INTO uw_Layout_themes VALUES
("Yotsuba", "yotsuba", "#FFD6AE"),
("Yotsuba B", "yotsuba-b", "#D0D5E7");


INSERT INTO uw_KeyVal_store VALUES
("defaultTheme", "yotsuba");


INSERT INTO uw_Data_tags VALUES
("test", "Test board");


INSERT INTO uw_Admin_affLinks VALUES
("https://github.com/steinuil/negoto", "source")
