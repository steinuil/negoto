datatype role = Owner | Admin | Moderator
  (* The permission levels of an account *)

val create : string -> string -> role -> transaction unit
  (* [create name password role] create an admin account *)

val changeName : string -> string -> transaction unit
  (* [changeName oldName newName] updates an admin's name *)

val changePassword : string -> string -> transaction unit

val delete : string -> transaction unit

val roleOf : string -> transaction (option role)
  (* Returns the role of an admin *)


val logIn : string -> string -> transaction unit
  (* Log in with the name and password *)

val logOutCurrent : transaction unit
  (* Log out of the current session *)

val authenticate : transaction string
  (* Check the authentication cookie and return the user's name *)

val invalidateAndRehash : transaction unit
  (* Invalidate all other sessions and rehash the current *)
