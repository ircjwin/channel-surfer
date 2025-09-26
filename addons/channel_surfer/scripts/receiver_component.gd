@tool
class_name ReceiverComponent
extends ChannelSurfer


const PARCEL_EXPECTED_TYPE: String = "parcel/expected_type"
const PARCEL_REQUEST_RESPONSES: String = "parcel_request/responses"

var expected_type: Script
var request_responses: Array[Resource] = []

## These could probably just be signals
var hear_ping: Callable
var open_parcel: Callable


func _ready() -> void:
    _receive(true)


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    properties.append({
        "name": PARCEL_EXPECTED_TYPE,
        "type": TYPE_OBJECT,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_RESOURCE_TYPE,
        "hint_string": "Script",
    })
    properties.append({
        "name": PARCEL_REQUEST_RESPONSES,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "%d/%d:Resource" % [TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE],
    })
    return properties


func _get(property: StringName) -> Variant:
    if property == PARCEL_EXPECTED_TYPE:
        return expected_type
    if property == PARCEL_REQUEST_RESPONSES:
        return request_responses
    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == PARCEL_EXPECTED_TYPE:
        expected_type = value
        return true
    if property == PARCEL_REQUEST_RESPONSES:
        request_responses = value
        return true
    return false


func receive_ping() -> void:
    if hear_ping.is_valid():
        hear_ping.call()


func receive_parcel(parcel: Resource) -> void:
    if expected_type.can_instantiate() and is_instance_of(parcel, expected_type):
        if open_parcel.is_valid():
            open_parcel.call(parcel)


func receive_parcel_request(parcel_request: Script, request_callback: Callable) -> void:
    if parcel_request.can_instantiate() and request_callback.is_valid():
        for request_response: Resource in request_responses:
            if is_instance_of(request_response, parcel_request):
                request_callback.call(request_response)
                return

