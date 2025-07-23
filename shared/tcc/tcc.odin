package tcc

import "base:runtime"
import "core:fmt"
import "core:strings"
import "core:os"
import "../../external/miniz"
import "../../external/libtcc"

import "../utils"

tcc_sdk :: #load("../../assets/release.zip")

compile_success := true

error_callback :: proc "c" (opaque: rawptr, msg: cstring) 
{
    context = runtime.default_context()
    fmt.printf("TCC Error: %s\n", msg)
    compile_success = false
}

Tcc :: struct {
    include_dir: cstring,
    lib_dir: cstring,
}

Tcc_Init :: proc() -> Tcc
{
    //create temp folder
    temp_dir := utils.get_temp_dir()
    sdk_dir := strings.concatenate({temp_dir, "/compiler_rt/"})

    include_dir := strings.clone_to_cstring(strings.concatenate({sdk_dir, "/include"}))
    lib_dir := strings.clone_to_cstring(strings.concatenate({sdk_dir, "/lib"}))

    os.make_directory(sdk_dir)
    miniz.extract_zip_from_memory(tcc_sdk, sdk_dir)

    return {
        include_dir,
        lib_dir
    }
}

Tcc_Compile :: proc(this: ^Tcc, code: string, output_file: string) -> bool
{
    state := libtcc.tcc_new()

    libtcc.tcc_set_output_type(state, libtcc.TCC_OUTPUT_EXE)

    libtcc.tcc_add_include_path(state, this.include_dir)

    libtcc.tcc_add_library_path(state, this.lib_dir)

    libtcc.tcc_compile_string(state, strings.clone_to_cstring(code))

    libtcc.tcc_output_file(state, strings.clone_to_cstring(output_file))

    return compile_success
}