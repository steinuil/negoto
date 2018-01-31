(** Managing accounts *)

datatype role = Owner | Admin | Moderator
  (* The permission levels of an account *)

val ord_role  : ord role
val read_role : read role
val show_role : show role

val all : transaction (list { Nam : string, Role : role })

val create : string -> string -> role -> transaction unit
  (* [create name password role] create an admin account *)

val changeName : string -> string -> transaction unit
  (* [changeName oldName newName] updates an admin's name *)

val changePassword : string -> string -> string -> transaction unit
  (* [changePassword name oldPass newPass] changes a user's password to [newPass] *)

val delete : string -> transaction unit

val roleOf : string -> transaction (option role)
  (* Returns the role of an admin *)


(** Managing logins *)

val logIn : string -> string -> transaction unit
  (* Log in with the name and password *)

val logOutCurrent : transaction unit
  (* Log out of the current session *)

val authenticate : transaction string
  (* Check the authentication cookie and return the user's name *)

val authenticateOpt : transaction (option string)
  (* Like [authenticate], but returns None on failure *)

val requireLevel : role -> transaction (string * role)
  (* Like [authenticate], but also checks that the authenticated user's role
   * has permissions equal or superior to the given role. *)

val invalidateAndRehash : transaction unit
  (* Invalidate all other sessions and rehash the current *)
