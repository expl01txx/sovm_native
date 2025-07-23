package libtcc

import "core:c"

foreign import libtcc "libtcc.lib"

TCC_State_Opaque :: struct {}
TCCState :: ^TCC_State_Opaque


TCC_OUTPUT_MEMORY     :: 1
TCC_OUTPUT_EXE        :: 2
TCC_OUTPUT_DLL        :: 3
TCC_OUTPUT_OBJ        :: 4
TCC_OUTPUT_PREPROCESS :: 5

TCC_RELOCATE_AUTO :: 1

foreign libtcc {
    tcc_new :: proc() -> TCCState ---
    tcc_delete :: proc(s: TCCState) ---
    tcc_compile_string :: proc(s: TCCState, buf: cstring) -> c.int ---
    tcc_output_file :: proc(s: TCCState, filename: cstring) -> c.int ---
    tcc_set_output_type :: proc(s: TCCState, output_type: c.int) -> c.int ---
    tcc_add_include_path :: proc(s: TCCState, path: cstring) -> c.int ---
    tcc_add_library_path :: proc(s: TCCState, path: cstring) -> c.int ---
    tcc_set_error_func :: proc(s: TCCState, error_opaque: rawptr, error_func: proc "c" (opaque: rawptr, msg: cstring)) ---
}