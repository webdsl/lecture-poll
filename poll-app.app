application pollapp

entity Poll {
  question : WikiText ( name )
  options : [PollOption]
}

entity PollOption {
  poll : Poll ( inverse = options )
  answer : WikiText (name)
  responses : {PollResponse}
  total : Int := responses.length
}

entity PollResponse {
  chosenOption : PollOption ( inverse = responses )
}

session answered {
  polls : {Poll}
}

page root {
  var u := securityContext.principal
  var newpass : Secret
  if( loggedIn() ){
    form {
      input( newpass ){ validate( newpass.length() >= 6, "at least 6 characters" ) }
      submit action{ u.password := newpass.digest(); }{ "Update password" }
    }
  } else {
    authentication
  }
  navigate admin(){ "admin" }
}

page poll( p: Poll ){
  <style>
    label {
      display: block;
    }
  </style>
  var r := PollResponse{}
  if( ! (p in answered.polls) ){
    div{ output( p.question ) }
    form {
      radio( r.chosenOption, p.options )
      validate( r.chosenOption != null, "Pick one option" )
      br br
      submitlink action {
        answered.polls.add( p );
      }{ "Confirm" }
    }
  }
  else {
    "poll already answered"
    div{ navigate viewAnswers( p ){ "view answers for ~p.question" } }
  }
}

page viewAnswers( p: Poll ){
  placeholder page {
    div{ output( p.question ) }
    for( o in p.options order by o.total desc ) {
      div{ output( o.total ) output( o.answer ) }
      br br
    }
  }
  refreshPlaceholder( page )
  navigate admin() { "admin" }
}

page editPoll( p: Poll ){
  form {
    div{
      label( "question" ){
        input( p.question )
      }
    }
    for( o in p.options){
      div{ label( "answer" ){ input( o.answer ) } }
    }
    submit action{}{ "save" }
    submit action{ p.options.add( PollOption{} ); }{ "save and add answer option" }
  }
  navigate admin() { "admin" }
}

page admin {
  for( p: Poll ){
    div{ navigate poll( p ){ "poll page to share" } }
    div{ navigate viewAnswers( p ){ "view answers for ~p.question" } }
    div{ navigate editPoll( p ){ "edit poll" } }
  }
  submit action{ Poll{}.save(); }{ "create new poll" }
}

template refreshPlaceholder( ph: Placeholder ){
  submitlink action{ replace( ph ); }[ id = "refresh", style = "display:none;" ]{ "refresh" }
    <script>
      var refreshtimer;
      function setRefreshTimer(){
        clearTimeout(refreshtimer);
        refreshtimer = setTimeout(function() {
          $("#refresh").click();
          setRefreshTimer();
        },500);
      }
      setRefreshTimer();
    </script>
}

entity User {
  username : String
  password : Secret
}

var adminuser := User{ username := "admin" password := "123" }

principal is User with credentials username, password

access control rules
  rule page root(){ true }
  rule page admin(){ loggedIn() }
  rule page poll( p: Poll ){ true }
  rule page viewAnswers( p: Poll ){ true }
  rule page editPoll( p: Poll ){ loggedIn() }
