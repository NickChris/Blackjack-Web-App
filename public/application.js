$(document).ready(function(){
  player_hit();
  player_stay();
  dealer_hit();
  double_down();
});

function player_hit() {
  $(document).on("click", "form#hit_form input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    return false;
  });
}

function player_stay() {
  $(document).on("click", "form#stay_form input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/stay'
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    return false;
  });
}

function dealer_hit() {
  $(document).on("click", "form#dealer_hit input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/dealer/hit'
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    return false;
  });
}

function double_down() {
  $(document).on("click", "form#double_down input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/double_down'
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    return false;
  });
}