@tool
@icon("res://addons/channel_surfer/assets/receiver_icon.png")
class_name ChannelReceiver
extends ChannelSurfer


const PARCEL_EXPECTED: String = "parcel/expected"
const PARCEL_RESPONSES: String = "parcel/response"
const POSTCARD_EXPECTED: String = "postcard/expected"
const POSTCARD_RESPONSES: String = "postcard/response"

var parcel_expected: Array[String] = []
var parcel_response: Array[Object] = []
var postcard_expected: Array[String] = []
var postcard_response: Array = []

# These could probably just be signals
var hear_ping: Callable
var open_parcel: Callable


func _ready() -> void:
    _receive(true)


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []

    properties.append({
        "name": PARCEL_EXPECTED,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ARRAY_TYPE,
        "hint_string": "ParcelType",
    })
    properties.append({
        "name": PARCEL_RESPONSES,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "%d:" % [TYPE_OBJECT, ],
    })
    properties.append({
        "name": POSTCARD_EXPECTED,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ARRAY_TYPE,
        "hint_string": "PostcardType",
    })
    properties.append({
        "name": POSTCARD_RESPONSES,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "Variant",
    })
    return properties


func _get(property: StringName) -> Variant:
    if property == PARCEL_EXPECTED:
        return parcel_expected
    if property == PARCEL_RESPONSES:
        return parcel_response
    if property == POSTCARD_EXPECTED:
        return postcard_expected
    if property == POSTCARD_RESPONSES:
        return postcard_response
    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == PARCEL_EXPECTED:
        parcel_expected = value
        return true
    if property == PARCEL_RESPONSES:
        parcel_response = value
        return true
    if property == POSTCARD_EXPECTED:
        postcard_expected = value
        return true
    if property == POSTCARD_RESPONSES:
        postcard_response = value
        return true
    return false


func receive_ping() -> void:
    if hear_ping.is_valid():
        hear_ping.call()


# func receive_parcel(parcel: Resource) -> void:
#     if parcel_expected.can_instantiate() and is_instance_of(parcel, parcel_expected):
#         if open_parcel.is_valid():
#             open_parcel.call(parcel)


# func receive_parcel_request(parcel_request: Script, request_callback: Callable) -> void:
#     if parcel_request.can_instantiate() and request_callback.is_valid():
#         for request_response: Resource in parcel_response:
#             if is_instance_of(request_response, parcel_request):
#                 request_callback.call(request_response)
#                 return
