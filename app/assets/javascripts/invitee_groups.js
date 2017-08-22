$(document).on('turbolinks:load', function(){
  var index = 0;
  $( ".new-member" ).click(function(event) {
    event.preventDefault();
    index = $('#members label').length;
    $("#members").append( "<div class='member-fields'><label for='invitee_group_members_" + index + "_name'>Name</label> <input type='text' name='invitee_group[members][" + index + "][name]' id='invitee_group_members_" + index + "_name' /><button class='remove-member' type='button'>Remove</button></button></div>");
    $(".remove-member").click(function(event) {
      event.preventDefault();
      $(this).parent().remove();
    });
  });
  $(".hide-fields").click(function(event) {
    event.preventDefault();
    var res = confirm("Are you sure?");
    if (res) {
      var member_block = $(this).parent();
      member_block.hide();
      member_block.children('input').val('');
    }
  });
});