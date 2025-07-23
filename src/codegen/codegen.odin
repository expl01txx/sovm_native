package codegen

import "core:strings"
import "core:fmt"
import "core:strconv"
import "../parser"

CodeGen :: struct {
    instructions: []parser.Instruction
}

CodeGen_Init :: proc(instructions: []parser.Instruction) -> CodeGen {
    return CodeGen{
        instructions
    }
}

CodeGen_Run :: proc(this: ^CodeGen) -> string {
    code: string
    for inst in this.instructions {
        switch inst.opcode {
            case "mov":
                reg1 := inst.args[0].(int)
                number := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] = %d;\n", reg1, number)})
    
            case "movr":
                reg1 := inst.args[0].(int)
                reg2 := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] = regs[%d];\n", reg1, reg2)})

            case "inc":
                reg1 := inst.args[0].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] += 1;\n", reg1)})

            case "dec":
                reg1 := inst.args[0].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] -= 1;\n", reg1)})

            case "add":
                reg1 := inst.args[0].(int)
                reg2 := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] += regs[%d];\n", reg1, reg2)})

            case "sub":
                reg1 := inst.args[0].(int)
                reg2 := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] -= regs[%d];\n", reg1, reg2)})

            case "mul":
                reg1 := inst.args[0].(int)
                reg2 := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] *= regs[%d];\n", reg1, reg2)})

            case "div":
                reg1 := inst.args[0].(int)
                reg2 := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("regs[%d] /= regs[%d];\n", reg1, reg2)})

            case "cmp":
                reg1 := inst.args[0].(int)
                reg2 := inst.args[1].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("zf = regs[%d] == regs[%d];\n", reg1, reg2)})

            case "label":
                label := inst.args[0].(string)
                code, _ = strings.concatenate({code, fmt.aprintf("%s:\n", label)})

            case "jmp":
                label := inst.args[0].(string)
                code, _ = strings.concatenate({code, fmt.aprintf("goto %s;\n", label)})

            case "je":
                label := inst.args[0].(string)
                code, _ = strings.concatenate({code, fmt.aprintf("if (zf) {{ goto %s; }};", label)})

            case "jne":
                label := inst.args[0].(string)
                code, _ = strings.concatenate({code, fmt.aprintf("if (!zf) {{ goto %s; }};", label)})

            case "in":
                reg1 := inst.args[0].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("scanf(\"%%d\", &regs[%d]);\n", reg1)})

            case "out":
                reg1 := inst.args[0].(int)
                code, _ = strings.concatenate({code, fmt.aprintf("printf(\"%%d\\n\", regs[%d]);\n", reg1)})

            case "puts":
                text := inst.args[0].(string)
                code, _ = strings.concatenate({code, fmt.aprintf("printf(\"%s\");\n", text)})

            case "halt":
                code, _ = strings.concatenate({code, "exit(0);\n"})
                
            case:
                fmt.println("Undefined instruction: ", inst.opcode)
        }
    }

    return code
}