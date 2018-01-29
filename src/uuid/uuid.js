var Uuid = {
  random: function() {
    var buf = new Uint8Array(16);
    window.crypto.getRandomValues(buf);

    // Set the leftmost bits to 0100 to set version 4
    buf[6] &= 0x0F;
    buf[6] |= 0x40;

    // Set the leftmost bits to 10 to set variant 1
    buf[8] &= 0x3F;
    buf[8] |= 0x80;

    var h = function(i) {
      var out = i.toString(16);
      if (out.length < 2) {
        out = "0".concat(out);
      }
      return out;
    }

    var out = "".concat(
      h(buf[0]), h(buf[1]), h(buf[2]), h(buf[3]), "-",
      h(buf[4]), h(buf[5]), "-",
      h(buf[6]), h(buf[7]), "-",
      h(buf[8]), h(buf[9]), "-",
      h(buf[10]), h(buf[11]), h(buf[12]),
      h(buf[13]), h(buf[14]), h(buf[15])
    );

    return out;
  }
}
