(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

open Loc
open Pp
open Names
open Entries
open Environ
open Libnames
open Libobject
open Lib
open Vernacexpr

(** This modules provides official functions to declare modules and
  module types *)

val subst_scope : string -> string

(** {6 Modules } *)

(** [declare_module interp_modtype interp_modexpr id fargs typ expr]
   declares module [id], with type constructed by [interp_modtype]
   from functor arguments [fargs] and [typ] and with module body
   constructed by [interp_modtype] from functor arguments [fargs] and
   by [interp_modexpr] from [expr]. At least one of [typ], [expr] must
   be non-empty.

   The [bool] in [typ] tells if the module must be abstracted [true]
   with respect to the module type or merely matched without any
   restriction [false].
*)

val declare_module :
  (env -> 'modast -> module_struct_entry) ->
  (env -> 'modast -> module_struct_entry) ->
  (env -> 'modast -> module_struct_entry * bool) ->
  Id.t ->
  (Id.t located list * ('modast annotated)) list ->
  ('modast annotated) module_signature ->
  ('modast annotated) list -> module_path

val start_module : (env -> 'modast -> module_struct_entry) ->
  bool option -> Id.t ->
  (Id.t located list * ('modast annotated)) list ->
  ('modast annotated) module_signature -> module_path

val end_module : unit -> module_path



(** {6 Module types } *)

val declare_modtype : (env -> 'modast -> module_struct_entry) ->
  (env -> 'modast -> module_struct_entry * bool) ->
  Id.t ->
  (Id.t located list * ('modast annotated)) list ->
  ('modast annotated) list ->
  ('modast annotated) list ->
  module_path

val start_modtype : (env -> 'modast -> module_struct_entry) ->
  Id.t -> (Id.t located list * ('modast annotated)) list ->
  ('modast annotated) list -> module_path

val end_modtype : unit -> module_path


(** {6 ... } *)
(** Objects of a module. They come in two lists: the substitutive ones
  and the other *)

val module_objects : module_path -> library_segment


(** {6 Libraries i.e. modules on disk } *)

type library_name = DirPath.t

type library_objects

val register_library :
  library_name ->
    Safe_typing.compiled_library -> library_objects -> Digest.t -> unit

val get_library_symbols_tbl : library_name -> Nativecode.symbol array

val start_library : library_name -> unit

val end_library :
  library_name ->
    Safe_typing.compiled_library * library_objects * Safe_typing.native_library

(** [really_import_module mp] opens the module [mp] (in a Caml sense).
   It modifies Nametab and performs the [open_object] function for
   every object of the module. Raises [Not_found] when [mp] is unknown. *)

val really_import_module : module_path -> unit

(** [import_module export mp] is a synchronous version of
   [really_import_module]. If [export] is [true], the module is also
   opened every time the module containing it is. *)

val import_module : bool -> module_path -> unit

(** Include  *)

val declare_include : (env -> 'struct_expr -> module_struct_entry * bool) ->
  ('struct_expr annotated) list -> unit

(** {6 ... } *)
(** [iter_all_segments] iterate over all segments, the modules'
    segments first and then the current segment. Modules are presented
    in an arbitrary order. The given function is applied to all leaves
    (together with their section path). *)

val iter_all_segments : (object_name -> obj -> unit) -> unit


val debug_print_modtab : unit -> Pp.std_ppcmds

(** For Printer *)
val process_module_seb_binding :
  MBId.t -> Declarations.struct_expr_body -> unit
