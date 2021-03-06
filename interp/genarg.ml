(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

open Pp
open Util
open Glob_term
open Constrexpr
open Misctypes

type argument_type =
  (* Basic types *)
  | BoolArgType
  | IntArgType
  | IntOrVarArgType
  | StringArgType
  | PreIdentArgType
  | IntroPatternArgType
  | IdentArgType of bool
  | VarArgType
  | RefArgType
  (* Specific types *)
  | SortArgType
  | ConstrArgType
  | ConstrMayEvalArgType
  | QuantHypArgType
  | OpenConstrArgType of bool
  | ConstrWithBindingsArgType
  | BindingsArgType
  | RedExprArgType
  | List0ArgType of argument_type
  | List1ArgType of argument_type
  | OptArgType of argument_type
  | PairArgType of argument_type * argument_type
  | ExtraArgType of string

let rec argument_type_eq arg1 arg2 = match arg1, arg2 with
| BoolArgType, BoolArgType -> true
| IntArgType, IntArgType -> true
| IntOrVarArgType, IntOrVarArgType -> true
| StringArgType, StringArgType -> true
| PreIdentArgType, PreIdentArgType -> true
| IntroPatternArgType, IntroPatternArgType -> true
| IdentArgType b1, IdentArgType b2 -> (b1 : bool) == b2
| VarArgType, VarArgType -> true
| RefArgType, RefArgType -> true
| SortArgType, SortArgType -> true
| ConstrArgType, ConstrArgType -> true
| ConstrMayEvalArgType, ConstrMayEvalArgType -> true
| QuantHypArgType, QuantHypArgType -> true
| OpenConstrArgType b1, OpenConstrArgType b2 -> (b1 : bool) == b2
| ConstrWithBindingsArgType, ConstrWithBindingsArgType -> true
| BindingsArgType, BindingsArgType -> true
| RedExprArgType, RedExprArgType -> true
| List0ArgType arg1, List0ArgType arg2 -> argument_type_eq arg1 arg2
| List1ArgType arg1, List1ArgType arg2 -> argument_type_eq arg1 arg2
| OptArgType arg1, OptArgType arg2 -> argument_type_eq arg1 arg2
| PairArgType (arg1l, arg1r), PairArgType (arg2l, arg2r) ->
  argument_type_eq arg1l arg2l && argument_type_eq arg1r arg2r
| ExtraArgType s1, ExtraArgType s2 -> CString.equal s1 s2
| _ -> false

let loc_of_or_by_notation f = function
  | AN c -> f c
  | ByNotation (loc,s,_) -> loc

type glob_constr_and_expr = glob_constr * constr_expr option
type open_constr_expr = unit * constr_expr
type open_glob_constr = unit * glob_constr_and_expr

type glob_constr_pattern_and_expr = glob_constr_and_expr * Pattern.constr_pattern

type ('raw, 'glob, 'top) genarg_type = argument_type

type 'a uniform_genarg_type = ('a, 'a, 'a) genarg_type
(** Alias for concision *)

(* Dynamics but tagged by a type expression *)

type rlevel
type glevel
type tlevel

type 'a generic_argument = argument_type * Obj.t
type raw_generic_argument = rlevel generic_argument
type glob_generic_argument = glevel generic_argument
type typed_generic_argument = tlevel generic_argument

let rawwit t = t
let glbwit t = t
let topwit t = t

let wit_bool = BoolArgType

let wit_int = IntArgType

let wit_int_or_var = IntOrVarArgType

let wit_string = StringArgType

let wit_pre_ident = PreIdentArgType

let wit_intro_pattern = IntroPatternArgType

let wit_ident_gen b = IdentArgType b

let wit_ident = wit_ident_gen true

let wit_pattern_ident = wit_ident_gen false

let wit_var = VarArgType

let wit_ref = RefArgType

let wit_quant_hyp = QuantHypArgType

let wit_sort = SortArgType

let wit_constr = ConstrArgType

let wit_constr_may_eval = ConstrMayEvalArgType

let wit_open_constr_gen b = OpenConstrArgType b

let wit_open_constr = wit_open_constr_gen false

let wit_casted_open_constr = wit_open_constr_gen true

let wit_constr_with_bindings = ConstrWithBindingsArgType

let wit_bindings = BindingsArgType

let wit_red_expr = RedExprArgType

let wit_list0 t = List0ArgType t

let wit_list1 t = List1ArgType t

let wit_opt t = OptArgType t

let wit_pair t1 t2 = PairArgType (t1,t2)

let in_gen t o = (t,Obj.repr o)
let out_gen t (t',o) = if argument_type_eq t t' then Obj.magic o else failwith "out_gen"
let genarg_tag (s,_) = s

let fold_list0 f = function
  | (List0ArgType t, l) ->
      List.fold_right (fun x -> f (in_gen t x)) (Obj.magic l)
  | _ -> failwith "Genarg: not a list0"

let fold_list1 f = function
  | (List1ArgType t, l) ->
      List.fold_right (fun x -> f (in_gen t x)) (Obj.magic l)
  | _ -> failwith "Genarg: not a list1"

let fold_opt f a = function
  | (OptArgType t, l) ->
      (match Obj.magic l with
	| None -> a
	| Some x -> f (in_gen t x))
  | _ -> failwith "Genarg: not a opt"

let fold_pair f = function
  | (PairArgType (t1,t2), l) ->
      let (x1,x2) = Obj.magic l in
      f (in_gen t1 x1) (in_gen t2 x2)
  | _ -> failwith "Genarg: not a pair"

let app_list0 f = function
  | (List0ArgType t as u, l) ->
      let o = Obj.magic l in
      (u, Obj.repr (List.map (fun x -> out_gen t (f (in_gen t x))) o))
  | _ -> failwith "Genarg: not a list0"

let app_list1 f = function
  | (List1ArgType t as u, l) ->
      let o = Obj.magic l in
      (u, Obj.repr (List.map (fun x -> out_gen t (f (in_gen t x))) o))
  | _ -> failwith "Genarg: not a list1"

let app_opt f = function
  | (OptArgType t as u, l) ->
      let o = Obj.magic l in
      (u, Obj.repr (Option.map (fun x -> out_gen t (f (in_gen t x))) o))
  | _ -> failwith "Genarg: not an opt"

let app_pair f1 f2 = function
  | (PairArgType (t1,t2) as u, l) ->
      let (o1,o2) = Obj.magic l in
      let o1 = out_gen t1 (f1 (in_gen t1 o1)) in
      let o2 = out_gen t2 (f2 (in_gen t2 o2)) in
      (u, Obj.repr (o1,o2))
  | _ -> failwith "Genarg: not a pair"

let unquote x = x

type an_arg_of_this_type = Obj.t

let in_generic t x = (t, Obj.repr x)

let dyntab = ref ([] : (string * glevel generic_argument option) list)

type ('a,'b) abstract_argument_type = argument_type
type 'a raw_abstract_argument_type = ('a,rlevel) abstract_argument_type
type 'a glob_abstract_argument_type = ('a,glevel) abstract_argument_type
type 'a typed_abstract_argument_type = ('a,tlevel) abstract_argument_type

let create_arg v s =
  if List.mem_assoc s !dyntab then
    Errors.anomaly ~label:"Genarg.create" (str ("already declared generic argument " ^ s));
  let t = ExtraArgType s in
  dyntab := (s,Option.map (in_gen t) v) :: !dyntab;
  t

let default_empty_argtype_value s = List.assoc s !dyntab

let default_empty_value t =
  let rec aux = function
  | List0ArgType _ -> Some (in_gen t [])
  | OptArgType _ -> Some (in_gen t None)
  | PairArgType(t1,t2) ->
      (match aux t1, aux t2 with
      | Some (_,v1), Some (_,v2) -> Some (in_gen t (v1,v2))
      | _ -> None)
  | ExtraArgType s -> default_empty_argtype_value s
  | _ -> None in
  match aux t with
  | Some v -> Some (out_gen t v)
  | None -> None
