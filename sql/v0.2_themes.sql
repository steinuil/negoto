ALTER TABLE uw_Layout_themes RENAME TO uw_Layout_themes_old;
CREATE TABLE uw_Layout_themes(
  uw_nam text NOT NULL,
  uw_link text NOT NULL,
  uw_handle integer NOT NULL,
  uw_tabcolor text NOT NULL,
  CONSTRAINT uw_Layout_themes_pkey PRIMARY KEY (uw_handle),
  CONSTRAINT uw_Layout_themes_UniqueName UNIQUE (uw_nam)
);
INSERT INTO uw_Layout_themes SELECT * FROM uw_Layout_themes_old;
UPDATE uw_KeyVal_store SET uw_val = (SELECT uw_nam FROM uw_Layout_themes WHERE uw_handle = (SELECT uw_val FROM uw_KeyVal_store WHERE uw_key = 'defaultTheme')) WHERE uw_key = 'defaultTheme';
DROP TABLE uw_Layout_themes_old;
