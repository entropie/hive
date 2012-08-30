$(document).ready(function () {
  console.log(1);

  $("#ajax-test-btn").click(function() {
    var url = $(this).attr("href");
    $("#ajax-test").load(url);
  });

});


