package tokenizer

import "core:fmt"
import "core:strings"

Tokenizer :: struct 
{
    pos: uint,
    source: string
}

TokenType :: enum 
{
    TOKEN_IDENT,
    TOKEN_REGISTER,
    TOKEN_NUMBER,
    TOKEN_COMMA,
    TOKEN_DOUBLE_QUOTES,
    TOKEN_STRING,
    TOKEN_LABEL,
    TOKEN_COMMENT,
    TOKEN_EOF,
    TOKEN_UNKNOWN
}

Token :: struct 
{
    type: TokenType,
    text: string
}

Token_Init :: proc(type: TokenType, text: string) -> Token 
{
    return Token{type, text}
}

Tokenizer_Init :: proc(source: string) -> Tokenizer 
{
    return Tokenizer{0, source}
}

Tokenizer_Peek :: proc(this: ^Tokenizer) -> u8 
{
    if this.pos >= len(this.source) {
        return 0
    }
    return this.source[this.pos]
}

Tokenizer_Advance :: proc(this: ^Tokenizer) -> u8 
{
    if this.pos >= len(this.source) {
        return 0
    }
    char := this.source[this.pos]
    this.pos += 1
    return char
}

Tokenizer_SkipWhiteSpace :: proc(this: ^Tokenizer) 
{
    for (strings.is_space(rune(Tokenizer_Peek(this)))) {
        Tokenizer_Advance(this)
    }
}

Tokenizer_NextToken :: proc(this: ^Tokenizer) -> Token 
{
    Tokenizer_SkipWhiteSpace(this)

    if this.pos >= len(this.source) {
        return Token_Init(.TOKEN_EOF, "")
    }

    c := Tokenizer_Advance(this)

    switch c {
        case ',':
            return Token_Init(.TOKEN_COMMA, this.source[this.pos-1:this.pos])

        case '0'..='9':
            str: [dynamic]u8
            append(&str, c)
            for {
                _char := Tokenizer_Peek(this)
                if _char < '0' || _char > '9' {
                    break
                }
                append(&str, Tokenizer_Advance(this))
            }
            return Token_Init(.TOKEN_NUMBER, string(str[:]))

        case '%':
            Tokenizer_Advance(this)
            return Token_Init(.TOKEN_REGISTER, this.source[this.pos-1:this.pos])

        case '.':
            str: [dynamic]u8
            for {
                _char := Tokenizer_Peek(this)
                if !((_char >= 'A' && _char <= 'Z') || (_char >= 'a' && _char <= 'z')) {
                    break
                }
                append(&str, Tokenizer_Advance(this))
            }
            return Token_Init(.TOKEN_LABEL, string(str[:]))

        case 'A'..='Z', 'a'..='z':
            str: [dynamic]u8
            append(&str, c)
            for {
                _char := Tokenizer_Peek(this)
                if !((_char >= 'A' && _char <= 'Z') || (_char >= 'a' && _char <= 'z')) {
                    break
                }
                append(&str, Tokenizer_Advance(this))
            }
            return Token_Init(.TOKEN_IDENT, string(str[:]))

        case '"':
            str: [dynamic]u8
            for {
                if this.pos >= len(this.source) {
                    break
                }
                _char := Tokenizer_Peek(this)
                if _char == '"' {
                    Tokenizer_Advance(this)
                    break
                }
                append(&str, Tokenizer_Advance(this))
            }
            return Token_Init(.TOKEN_STRING, string(str[:]))

        case 0:
            return Token_Init(.TOKEN_EOF, "")

        case:
            return Token_Init(.TOKEN_UNKNOWN, this.source[this.pos-1:this.pos])
    }
}

Tokenizer_Run :: proc(this: ^Tokenizer) -> [dynamic]Token 
{
    tokens: [dynamic]Token 
    for {
        token := Tokenizer_NextToken(this)
        append(&tokens, token)
        if token.type == .TOKEN_EOF {
            return tokens
        }
    }
}
