(**
 * Copyright (c) 2014, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the "hack" directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 *)

external get_embedded_hhi_data : string -> string option =
  "get_embedded_hhi_data"

(* There are several verify-use race conditions here (and in Hack's file
 * handling in general, really). Running the server as root is likely to be a
 * security risk. Be careful. *)
let extract data =
  let tmpdir = Tmp.temp_dir "hhi" in
  let path = Path.mk_path tmpdir in
  let oc = Unix.open_process_out ("tar xzC " ^ (Path.string_of_path path)) in
  output_string oc data;
  flush oc;
  ignore (Unix.close_process_out oc);
  path

let extract_embedded () =
  match get_embedded_hhi_data Sys.executable_name with
  | None -> None
  | Some data -> Some (extract data)

let extract_external () =
  let path = (Filename.dirname Sys.executable_name) ^ "/../hhi.tar.gz" in
  if Sys.file_exists path then Some (extract (Utils.cat path)) else None

let get_hhi_root_impl () =
  match extract_embedded () with
  | Some path -> Some path
  | None -> extract_external ()

(* OCaml handles the value restriction much better than SML. <3 *)
let root = ref None

(* We want this to be idempotent so that later code can check if a given file
 * came from the hhi unarchive directory or not, to provide better error
 * messages. *)
let get_hhi_root () =
  match !root with
  | Some r -> r
  | None ->
      let r = get_hhi_root_impl () in
      root := Some r;
      r
