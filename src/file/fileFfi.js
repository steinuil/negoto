var NEGOTO_STATIC_DIR = "/static";

var UrWeb = {
  FileFfi: {
    link: function(section, name) {
      return NEGOTO_STATIC_DIR + "/" + section + "/" + name;
    }
  }
};
