(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

type 'a node =
| Nil
| Cons of 'a * 'a t

and 'a t = 'a node Lazy.t

let empty = Lazy.lazy_from_val Nil

let cons x s = Lazy.lazy_from_val (Cons (x, s))

let thunk s = lazy (Lazy.force (Lazy.force s))

let rec force s = match Lazy.force s with
| Nil -> ()
| Cons (_, s) -> force s

let force s = force s; s

let rec is_empty s = match Lazy.force s with
| Nil -> true
| Cons (_, _) -> false

let peek s = match Lazy.force s with
| Nil -> None
| Cons (x, s) -> Some (x, s)

let rec of_list = function
| [] -> empty
| x :: l -> cons x (of_list l)

let rec to_list s = match Lazy.force s with
| Nil -> []
| Cons (x, s) -> x :: (to_list s)

let rec iter f s = match Lazy.force s with
| Nil -> ()
| Cons (x, s) -> f x; iter f s

let rec map_node f = function
| Nil -> Nil
| Cons (x, s) -> Cons (f x, map f s)

and map f s = lazy (map_node f (Lazy.force s))

let rec app_node n1 s2 = match n1 with
| Nil -> Lazy.force s2
| Cons (x, s1) -> Cons (x, app s1 s2)

and app s1 s2 = lazy (app_node (Lazy.force s1) s2)

let rec fold f accu s = match Lazy.force s with
| Nil -> accu
| Cons (x, s) -> fold f (f accu x) s

let rec map_filter_node f = function
| Nil -> Nil
| Cons (x, s) ->
  begin match f x with
  | None -> map_filter_node f (Lazy.force s)
  | Some y -> Cons (y, map_filter f s)
  end

and map_filter f s = lazy (map_filter_node f (Lazy.force s))

let rec concat_node = function
| Nil -> empty
| Cons (s, sl) -> app s (concat sl)

and concat (s : 'a t t) =
  thunk (lazy (concat_node (Lazy.force s)))

let lempty = empty
