package utils

import "core:sys/windows"

get_temp_dir :: proc() -> string 
{
    temp := [1024]windows.WCHAR{}
    windows.GetTempPathW(1024, &temp[0])

    temp_dir, convert_err := windows.utf16_to_utf8_alloc(temp[:])

    return temp_dir
}
