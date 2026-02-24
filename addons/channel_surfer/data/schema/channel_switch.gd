extends Resource


@export var name: String
@export var methods: Array


class MethodSwitch:
    var name: String
    var params: Array


class ParamSwitch:
    var name: String
    var type: String


func _get(property: StringName) -> Variant:
    return null


func _set(property: StringName, value: Variant) -> bool:
    return false
