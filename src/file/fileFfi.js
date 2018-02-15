var NEGOTO_STATIC_DIR = "/public";

var FileFfi = {
  link: function(section, name) {
    return NEGOTO_STATIC_DIR + "/" + section + "/" + name;
  }
};
