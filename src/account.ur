datatype role = Owner | Admin | Moderator


fun int_of_role role =
  case role of
  | Owner => 2
  | Admin => 1
  | Moderator => 0

fun role_of_int role =
  case role of
  | 2 => Owner
  | 1 => Admin
  | 0 => Moderator
  | _ => error <xml>Invalid role</xml>

(* Some typeclass implementations for roles *)
val ord_role =
  mkOrd { Lt = (fn x y => lt (int_of_role x) (int_of_role y))
        , Le = (fn x y => le (int_of_role x) (int_of_role y)) }

val read_role = let
    fun read' x =
      case x of
      | "owner"     => Some Owner
      | "admin"     => Some Admin
      | "moderator" => Some Moderator
      | _ => None
  in
    mkRead
      (fn x => case read' x of
        | None => error <xml>Invalid role: {[x]}</xml>
        | Some x => x)
      read'
  end

val show_role =
  mkShow (fn x =>
    case x of
    | Owner     => "owner"
    | Admin     => "admin"
    | Moderator => "moderator")


(* Admin management *)
table admins :
  { Nam  : string
  , Role : int
  , Hash : string }
  PRIMARY KEY (Nam),


val all =
  query (SELECT * FROM admins)
    (fn { Admins = a } acc =>
      return ((a -- #Hash -- #Role ++ { Role = role_of_int a.Role }) :: acc))
    []


fun create name pass role =
  hash <- Bcrypt.hash pass;
  dml (INSERT INTO admins (Nam, Role, Hash)
       VALUES ( {[name]}, {[int_of_role role]}, {[hash]} ))


fun changeName oldName newName =
  dml (UPDATE admins SET Nam = {[newName]} WHERE Nam = {[oldName]})


fun changePassword name newPass =
  hash <- Bcrypt.hash newPass;
  dml (UPDATE admins SET Hash = {[hash]}
       WHERE Nam = {[name]})


fun delete name =
  dml (DELETE FROM admins WHERE Nam = {[name]})


fun validate name pass =
  x <- oneOrNoRows1 (SELECT admins.Hash FROM admins
                     WHERE admins.Nam = {[name]});
  case x of
  | Some { Hash = hash } =>
    return (Bcrypt.check pass hash)
  | None =>
    return False


fun roleOf name =
  r <- oneOrNoRows1 (SELECT admins.Role FROM admins WHERE admins.Nam = {[name]});
  case r of
  | Some { Role = role } => return (Some (role_of_int role))
  | None => return None


(* Add an owner account if there is none *)
task initialize = fn () =>
  x <- oneOrNoRows1 (SELECT * FROM admins WHERE admins.Role = {[int_of_role Owner]});
  case x of
  | Some _ => return ()
  | None => create "owner" "password" Owner



(* Manage logins *)
cookie loginToken :
  { User  : string
  , Token : string }


table logged :
  { User : string
  , Hash : string }
  CONSTRAINT User FOREIGN KEY User
    REFERENCES admins(Nam)
    ON UPDATE CASCADE
    ON DELETE CASCADE


fun getHash name token =
  tokens <- queryL1 (SELECT logged.Hash FROM logged
                     WHERE logged.User = {[name]});
  case List.find (fn x => Bcrypt.check token x.Hash) tokens of
  | Some { Hash = hash, ... } => return (Some hash)
  | None => return None


val getAuth =
  tok <- getCookie loginToken;
  case tok of
  | None => return None
  | Some { User = name, Token = token } =>
    hash <- getHash name token;
    (case hash of
    | None => return None
    | Some hash =>
      return (Some (name, hash)))


fun genLogin name =
  token <- Uuid.random;
  hash <- Bcrypt.hash token;
  dml (INSERT INTO logged (User, Hash)
       VALUES ( {[name]}, {[hash]} ));
  setCookie loginToken { Value = { User = name, Token = token }
                       , Expires = None, Secure = False }
  (* @Hack this cookie should be secure in version 1.0 *)


fun logIn name pass =
  valid <- validate name pass;
  if valid then
    genLogin name
  else
    error <xml>Incorrect username or password</xml>


fun logOut name token =
  hash <- getHash name token;
  case hash of
  | None => return ()
  | Some hash =>
    dml (DELETE FROM logged WHERE User = {[name]} AND Hash = {[hash]});
    clearCookie loginToken


fun logOutAll name =
  dml (DELETE FROM logged WHERE User = {[name]});
  clearCookie loginToken


val logOutCurrent =
  auth <- getAuth;
  clearCookie loginToken;
  case auth of
  | None => return ()
  | Some (name, hash) =>
    dml (DELETE FROM logged WHERE User = {[name]} AND Hash = {[hash]})


val authenticateOpt =
  auth <- getAuth;
  Option.mp (fn (name, _) => name) auth
  |> return


val authenticate =
  auth <- getAuth;
  case auth of
  | Some (name, _) => return name
  | None =>
    clearCookie loginToken;
    error <xml>Failed to authenticate</xml>


val invalidateAndRehash =
  name <- authenticate;
  logOutAll name;
  genLogin name


fun requireLevel lvl =
  name <- authenticate;
  role <- roleOf name;
  case role of
  | Some role =>
    if role >= lvl then
      return (name, role)
    else
      error <xml>You don't have permission to see this page.</xml>
  | None =>
    error <xml>UNEXPECTED: authenticated user doesn't exist in the users database.</xml>
