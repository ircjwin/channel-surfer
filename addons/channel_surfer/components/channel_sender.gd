@tool
@icon("res://addons/channel_surfer/assets/sender_icon.png")
class_name ChannelSender
extends ChannelSurfer


signal parcel_request_fulfilled(requested_parcel: Resource)

const PARCEL_CONTENTS: String = "parcel/contents"
const PARCEL_REQUEST: String = "parcel/request"
const POSTCARD_CONTENTS: String = "postcard/contents"
const POSTCARD_REQUEST: String = "postcard/request"

var parcel_contents: Array[Object]
var parcel_request: Array[String] = []
var postcard_contents: Array = []
var postcard_request: Array[String] = []

var react_opts: Array[Callable] = []
var react_sels: Array[String] = []


func _ready() -> void:
    react_opts.append(send_ping)
    react_opts.append(send_parcel)


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    var react_opts_string = "None," + ",".join(react_opts.map(func (x): return x.get_method()))
    properties.append({
        "name": &"react_sels",
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, react_opts_string, ],
    })
    properties.append({
        "name": PARCEL_CONTENTS,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "%d:" % [TYPE_OBJECT, ],
    })
    properties.append({
        "name": PARCEL_REQUEST,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ARRAY_TYPE,
        "hint_string": "ParcelType",
    })
    properties.append({
        "name": POSTCARD_CONTENTS,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "Variant",
    })
    properties.append({
        "name": POSTCARD_REQUEST,
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ARRAY_TYPE,
        "hint_string": "PostcardType",
    })
    return properties


func _get(property: StringName) -> Variant:
    if property == PARCEL_CONTENTS:
        return parcel_contents
    if property == PARCEL_REQUEST:
        return parcel_request
    if property == POSTCARD_CONTENTS:
        return postcard_contents
    if property == POSTCARD_REQUEST:
        return postcard_request
    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == PARCEL_CONTENTS:
        parcel_contents = value
        return true
    if property == PARCEL_REQUEST:
        parcel_request = value
        return true
    if property == POSTCARD_CONTENTS:
        postcard_contents = value
        return true
    if property == POSTCARD_REQUEST:
        postcard_request = value
        return true
    return false


func send_ping() -> void:
    get_tree().call_group(_get_most_precise(), "receive_ping")


func send_parcel() -> void:
    if parcel_contents:
        get_tree().call_group(_get_most_precise(), "receive_parcel", parcel_contents)


# func send_parcel_request() -> void:
#     if parcel_request:
#         get_tree().call_group(_get_most_precise(), "receive_parcel_request", parcel_request, _confirm_receipt)


# func _confirm_receipt(requested_parcel: Resource) -> void:
#     for request_type: Resource in parcel_request:
#         if request_type.can_instantiate() and is_instance_of(requested_parcel, request_type):
#             parcel_request_fulfilled.emit(requested_parcel)
#             break
