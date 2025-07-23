package miniz

import "core:bufio"
import "core:c"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:mem"
import "core:path/filepath"

// Miniz library bindings
foreign import miniz_lib "miniz.lib"

// Constants
MZ_ZIP_MAX_IO_BUF_SIZE :: 64*1024
MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE :: 512
MZ_ZIP_MAX_ARCHIVE_FILE_COMMENT_SIZE :: 512

// Enums
mz_zip_error :: enum c.int {
    MZ_ZIP_NO_ERROR = 0,
    MZ_ZIP_UNDEFINED_ERROR,
    MZ_ZIP_TOO_MANY_FILES,
    MZ_ZIP_FILE_TOO_LARGE,
    MZ_ZIP_UNSUPPORTED_METHOD,
    MZ_ZIP_UNSUPPORTED_ENCRYPTION,
    MZ_ZIP_UNSUPPORTED_FEATURE,
    MZ_ZIP_FAILED_FINDING_CENTRAL_DIR,
    MZ_ZIP_NOT_AN_ARCHIVE,
    MZ_ZIP_INVALID_HEADER_OR_CORRUPTED,
    MZ_ZIP_UNSUPPORTED_MULTIDISK,
    MZ_ZIP_DECOMPRESSION_FAILED,
    MZ_ZIP_COMPRESSION_FAILED,
    MZ_ZIP_UNEXPECTED_DECOMPRESSED_SIZE,
    MZ_ZIP_CRC_CHECK_FAILED,
    MZ_ZIP_UNSUPPORTED_CDIR_SIZE,
    MZ_ZIP_ALLOC_FAILED,
    MZ_ZIP_FILE_OPEN_FAILED,
    MZ_ZIP_FILE_CREATE_FAILED,
    MZ_ZIP_FILE_WRITE_FAILED,
    MZ_ZIP_FILE_READ_FAILED,
    MZ_ZIP_FILE_CLOSE_FAILED,
    MZ_ZIP_FILE_SEEK_FAILED,
    MZ_ZIP_FILE_STAT_FAILED,
    MZ_ZIP_INVALID_PARAMETER,
    MZ_ZIP_INVALID_FILENAME,
    MZ_ZIP_BUF_TOO_SMALL,
    MZ_ZIP_INTERNAL_ERROR,
    MZ_ZIP_FILE_NOT_FOUND,
    MZ_ZIP_ARCHIVE_TOO_LARGE,
    MZ_ZIP_VALIDATION_FAILED,
    MZ_ZIP_WRITE_CALLBACK_FAILED,
}

mz_zip_flags :: enum c.uint {
    MZ_ZIP_FLAG_CASE_SENSITIVE                = 0x0100,
    MZ_ZIP_FLAG_IGNORE_PATH                   = 0x0200,
    MZ_ZIP_FLAG_COMPRESSED_DATA               = 0x0400,
    MZ_ZIP_FLAG_DO_NOT_SORT_CENTRAL_DIRECTORY = 0x0800,
    MZ_ZIP_FLAG_VALIDATE_LOCATE_FILE_FLAG     = 0x1000,
    MZ_ZIP_FLAG_VALIDATE_HEADERS_ONLY         = 0x2000,
    MZ_ZIP_FLAG_WRITE_ZIP64                   = 0x4000,
    MZ_ZIP_FLAG_ASCII_FILENAME                = 0x8000,
}

// Structures
mz_zip_archive_file_stat :: struct {
    m_file_index:                c.uint,
    m_central_dir_ofs:          c.uint64_t,
    m_version_made_by:          c.uint16_t,
    m_version_needed:           c.uint16_t,
    m_bit_flag:                 c.uint16_t,
    m_method:                   c.uint16_t,
    m_time:                     c.uint32_t,
    m_crc32:                    c.uint32_t,
    m_comp_size:                c.uint64_t,
    m_uncomp_size:              c.uint64_t,
    m_internal_attr:            c.uint16_t,
    m_external_attr:            c.uint32_t,
    m_local_header_ofs:         c.uint64_t,
    m_filename_len:             c.uint32_t,
    m_comment_len:              c.uint32_t,
    m_filename:                 [MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE]c.char,
    m_comment:                  [MZ_ZIP_MAX_ARCHIVE_FILE_COMMENT_SIZE]c.char,
}

mz_zip_internal_state :: struct {} // Opaque structure

mz_zip_archive :: struct {
    m_archive_size:             c.uint64_t,
    m_central_directory_file_ofs: c.uint64_t,
    m_total_files:              c.uint32_t,
    m_zip_mode:                 c.uint32_t,
    m_zip_type:                 c.uint32_t,
    m_last_error:               mz_zip_error,
    m_file_offset_alignment:    c.uint64_t,
    m_pAlloc:                   rawptr,
    m_pFree:                    rawptr,
    m_pRealloc:                 rawptr,
    m_pAlloc_opaque:            rawptr,
    m_pRead:                    rawptr,
    m_pWrite:                   rawptr,
    m_pNeeds_keepalive:         rawptr,
    m_pIO_opaque:               rawptr,
    m_pState:                   ^mz_zip_internal_state,
}

// Foreign procedures
@(default_calling_convention="c")
foreign miniz_lib {
    mz_zip_reader_init_mem :: proc(pZip: ^mz_zip_archive, pMem: rawptr, size: c.size_t, flags: c.uint) -> c.int ---
    mz_zip_reader_end :: proc(pZip: ^mz_zip_archive) -> c.int ---
    mz_zip_reader_get_num_files :: proc(pZip: ^mz_zip_archive) -> c.uint ---
    mz_zip_reader_file_stat :: proc(pZip: ^mz_zip_archive, file_index: c.uint, pStat: ^mz_zip_archive_file_stat) -> c.int ---
    mz_zip_reader_get_filename :: proc(pZip: ^mz_zip_archive, file_index: c.uint, pFilename: cstring, filename_buf_size: c.uint) -> c.uint ---
    mz_zip_reader_extract_to_mem :: proc(pZip: ^mz_zip_archive, file_index: c.uint, pBuf: rawptr, buf_size: c.size_t, flags: c.uint) -> rawptr ---
    mz_zip_reader_extract_file_to_mem :: proc(pZip: ^mz_zip_archive, pFilename: cstring, pBuf: rawptr, buf_size: c.size_t, flags: c.uint) -> rawptr ---
}


// Helper functions
create_directory_recursive :: proc(path: string) -> bool {
    dir := filepath.dir(path)
    if dir == "." || dir == "/" {
        return true
    }
    
    if !os.exists(dir) {
        if !create_directory_recursive(dir) {
            return false
        }
        err := os.make_directory(dir)
        if err != os.ERROR_NONE {
            return false
        }
    }
    return true
}

extract_zip_from_memory :: proc(zip_data: []byte, extract_to: string) -> bool {
    zip_archive: mz_zip_archive
    
    if mz_zip_reader_init_mem(&zip_archive, raw_data(zip_data), len(zip_data), 0) == 0 {
        fmt.println("Failed to initialize zip reader")
        return false
    }
    defer mz_zip_reader_end(&zip_archive)
    
    num_files := mz_zip_reader_get_num_files(&zip_archive)
    
    for i in 0..<num_files {
        file_stat: mz_zip_archive_file_stat
        
        if mz_zip_reader_file_stat(&zip_archive, i, &file_stat) == 0 {
            fmt.printf("Failed to get file stat for file %d\n", i)
            continue
        }
        
        filename_buffer := make([]c.char, MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE)
        defer delete(filename_buffer)
        
        filename_len := mz_zip_reader_get_filename(&zip_archive, i, cstring(raw_data(filename_buffer)), MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE)
        if filename_len == 0 {
            fmt.printf("Failed to get filename for file %d\n", i)
            continue
        }
        
        filename := strings.clone_from_cstring(cstring(raw_data(filename_buffer)))
        defer delete(filename)
        
        if strings.has_suffix(filename, "/") {
            continue
        }
        
        output_path := filepath.join({extract_to, filename})
        defer delete(output_path)
        
        if !create_directory_recursive(output_path) {
            fmt.printf("Failed to create directory structure for: %s\n", output_path)
            continue
        }
        
        decompressed_size := file_stat.m_uncomp_size
        buffer := make([]byte, decompressed_size)
        defer delete(buffer)
        
        result := mz_zip_reader_extract_to_mem(&zip_archive, i, raw_data(buffer), len(buffer), 0)
        if result == nil {
            fmt.printf("Failed to extract file: %s\n", filename)
            continue
        }
        
        if os.exists(output_path) {
            continue
        }

        write_err := os.write_entire_file(output_path, buffer)
        if !write_err {
            fmt.printf("Failed to write file: %s (error: %v)\n", output_path, write_err)
            continue
        }
        
    }
    
    return true
}
