class_name IDGen
extends Resource


const ID_SIZE: int = 6
const LOWERCASE_A: int = 97
const LOWERCASE_Z: int = 122


static func generate() -> String:
    var new_id: String
    for i: int in range(ID_SIZE):
        var coin_flip: int = randi_range(0, 1)
        if coin_flip:
            var new_char: int = randi_range(LOWERCASE_A, LOWERCASE_Z)
            new_id += char(new_char)
        else:
            var new_digit: int = randi_range(0, 9)
            new_id += str(new_digit)
    return new_id
