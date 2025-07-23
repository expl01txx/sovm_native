package parser

import "core:fmt"
import "core:strconv"
import "../tokenizer"

Expr :: union 
{
    int,
    string,
}

Instruction :: struct 
{
    opcode: string,
    args: []Expr,
}

Parser :: struct 
{
    tokens: []tokenizer.Token,
    pos:    int,
}

Parser_Init :: proc(tokens: []tokenizer.Token) -> Parser
{
    return {
        tokens,
        0
    }
}

Parser_Peek :: proc(this: ^Parser) -> tokenizer.Token 
{
    if this.pos >= len(this.tokens) {
        return tokenizer.Token{.TOKEN_EOF, ""}
    }
    return this.tokens[this.pos]
}

Parser_Advance :: proc(this: ^Parser) -> tokenizer.Token 
{
    tok := Parser_Peek(this)
    this.pos += 1
    return tok
}

Parser_Match :: proc(this: ^Parser, expected: tokenizer.TokenType) -> bool 
{
    if Parser_Peek(this).type == expected {
        Parser_Advance(this)
        return true
    }
    return false
}

Parser_ParseExpr:: proc(this: ^Parser) -> Expr 
{
    tok := Parser_Advance(this)

    switch tok.type {
        case .TOKEN_NUMBER, .TOKEN_REGISTER:
            return strconv.atoi(tok.text)
        case .TOKEN_STRING, .TOKEN_LABEL:
            return tok.text
        case .TOKEN_COMMA, .TOKEN_COMMENT, .TOKEN_DOUBLE_QUOTES, .TOKEN_EOF, .TOKEN_UNKNOWN, .TOKEN_IDENT:
            return Expr{}
    }
    return Expr{}
}

Parser_ParseInstruction :: proc(this: ^Parser) -> Instruction 
{
    tok := Parser_Advance(this)
    if tok.type != .TOKEN_IDENT {
        fmt.printf("Expected instruction name, got %v\n", tok)
        return Instruction{}
    }

    args: [dynamic]Expr
    for Parser_Peek(this).type != .TOKEN_EOF && Parser_Peek(this).type != .TOKEN_IDENT  {
        if Parser_Match(this, .TOKEN_COMMA) {
            continue
        }
        append(&args, Parser_ParseExpr(this))
    }

    return Instruction{opcode = tok.text, args = args[:]}
}

Parser_Run :: proc(this: ^Parser, tokens: []tokenizer.Token) -> []Instruction 
{
    instructions: [dynamic]Instruction

    for Parser_Peek(this).type != .TOKEN_EOF {
        inst := Parser_ParseInstruction(this)
        append(&instructions, inst)
    }

    return instructions[:]
}
