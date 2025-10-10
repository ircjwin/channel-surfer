class_name CSUID
extends Resource


const UID_SIZE: int = 8
const UID_PREFIX: String = "csuid_"
const ASCII_INTEGER_0: int = 48
const ASCII_INTEGER_9: int = 57
const ASCII_UPPERCASE_A: int = 65
const ASCII_UPPERCASE_Z: int = 90
const ASCII_LOWERCASE_A: int = 97
const ASCII_LOWERCASE_Z: int = 122


static func generate() -> String:
    var new_uid: String = UID_PREFIX
    var ascii_symbols: Array[int]
    ascii_symbols.append_array(range(ASCII_INTEGER_0, ASCII_INTEGER_9))
    ascii_symbols.append_array(range(ASCII_UPPERCASE_A, ASCII_UPPERCASE_Z))
    ascii_symbols.append_array(range(ASCII_LOWERCASE_A, ASCII_LOWERCASE_Z))
    for i: int in range(UID_SIZE):
        var new_char: int = ascii_symbols.pick_random()
        new_uid += char(new_char)
    return new_uid
