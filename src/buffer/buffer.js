var Buffer = {
  create: function(len) {
    return [];
  },

  contents: function(buf) {
    return buf.join("");
  },

  length: function(buf) {
    return buf.length;
  },

  addChar: function(buf, chr) {
    buf.push(chr.toString());
  },

  addString: function(buf, str2) {
    buf.push(str2);
  }
}
