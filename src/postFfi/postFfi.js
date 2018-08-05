var PostFfi = {
  mkId: function(num) {
    return "post" + num.toString();
  },

  mkIdUrl: function(id) {
    return "#" + id;
  }
}
