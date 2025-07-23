package src

import "core:path/filepath"
import "core:unicode/utf8"
import "core:strings"
import "core:fmt"
import "core:os"

import tokeniser_lib "tokenizer"
import parser_lib "parser"
import codegen_lib "codegen"
import tcc_lib "../shared/tcc"
import stub "stub"

App :: struct 
{

}

App_Init :: proc() -> App 
{
    return {}
}

App_Run :: proc(this: ^App) 
{
    args := os.args

    if len(args) < 2 {
        fmt.println("Usage: %s <filename> - compile sovm instructions to native code", args[0])
    }

    filename := args[1]

    if !os.exists(filename) {
        fmt.printf("File {} not found", filename)
    }

    // TODO: Check for reading error
    content, _ := os.read_entire_file(filename)

    //Tokenize step
    tokenizer := tokeniser_lib.Tokenizer_Init(
        string(content)
    )
    tokens := tokeniser_lib.Tokenizer_Run(&tokenizer)
    
    //Parse step
    parser := parser_lib.Parser_Init(tokens[:])
    instructions := parser_lib.Parser_Run(&parser, tokens[:])

    //Code generation step
    codegen := codegen_lib.CodeGen_Init(instructions)
    code := codegen_lib.CodeGen_Run(&codegen)

    //Compile code
    tcc := tcc_lib.Tcc_Init()

    source := strings.concatenate({stub.RuntimeStub, "{\n", code, "\n}"})

    basename := filepath.base(filename)
    output_name := strings.concatenate({strings.trim_suffix(basename, ".sovm"), ".exe"})

    tcc_lib.Tcc_Compile(&tcc, source, output_name)
}