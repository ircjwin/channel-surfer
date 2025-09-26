@tool
class_name SenderComponent
extends ChannelSurfer


signal parcel_request_fulfilled(requested_parcel: Resource)

const PARCEL_CONTENTS: String = "parcel/parcel_contents"
const PARCEL_REQUEST_TYPE: String = "parcel_request/request_type"

var parcel: Resource
var parcel_request: Script


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    properties.append({
        "name": PARCEL_CONTENTS,
        "type": TYPE_OBJECT,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_RESOURCE_TYPE,
    })
    properties.append({
        "name": PARCEL_REQUEST_TYPE,
        "type": TYPE_OBJECT,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_RESOURCE_TYPE,
        "hint_string": "Script",
    })
    return properties


func _get(property: StringName) -> Variant:
    if property == PARCEL_CONTENTS:
        return parcel
    if property == PARCEL_REQUEST_TYPE:
        return parcel_request
    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == PARCEL_CONTENTS:
        parcel = value
        return true
    if property == PARCEL_REQUEST_TYPE:
        parcel_request = value
        return true
    return false


func send_ping() -> void:
    get_tree().call_group(_get_most_precise(), "receive_ping")


func send_parcel() -> void:
    if parcel:
        get_tree().call_group(_get_most_precise(), "receive_parcel", parcel)


func send_parcel_request() -> void:
    if parcel_request:
        get_tree().call_group(_get_most_precise(), "receive_parcel_request", parcel_request, _confirm_receipt)


func _confirm_receipt(requested_parcel: Resource) -> void:
    if parcel_request.can_instantiate() and is_instance_of(requested_parcel, parcel_request):
        parcel_request_fulfilled.emit(requested_parcel)
