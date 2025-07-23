//SOVM Native - native compiler for soufiw virtual machine
package main

import "src"

// Entry point
main :: proc() 
{
    app := src.App_Init()
    src.App_Run(&app)
}