@tool
extends Node


# TODO: SwitchScripter ?
const SCRIPT_NAME = "SCRIPT_NAME"
const FUNC_COMMENT = "FUNC_COMMENT"
const FUNC_NAME = "FUNC_NAME"
const FUNC_PARAMS = "FUNC_PARAMS"
const FUNC_ARGS = "FUNC_ARGS"

const HEADER_TEMPLATE = (
    "extends Resource\n" +
    "\n" +
    "\n" +
    "signal switch_flipped(channel_switch: String, method_switch: String, param_switches: Array)\n" +
    "\n" +
    "@export var channel_name: String = \"" + SCRIPT_NAME + "\"\n"
)

const COMMENT_TEMPLATE = (
    "\n" +
    "\n" +
    "## " + FUNC_COMMENT + "\n"
)

const FUNC_TEMPLATE = (
    "func " + FUNC_NAME + "(" + FUNC_PARAMS + ") -> void:\n" +
    "	switch_flipped.emit(channel_name, " + FUNC_NAME + ", [" + FUNC_ARGS + "])\n"
)


func build_script(script_name: String, func_dict: Dictionary) -> String:
    var script_content: String = _build_header(script_name)
    for func_name: String in func_dict.keys():
        script_content += _build_comment(func_name)
        script_content += _build_func(func_name, func_dict[func_name])
    return script_content


func _build_header(script_name: String) -> String:
    return HEADER_TEMPLATE.replace(SCRIPT_NAME, script_name)


func _build_comment(comment: String) -> String:
    return COMMENT_TEMPLATE.replace(FUNC_COMMENT, comment)


func _build_func(func_name: String, func_params: Array) -> String:
    var params_array: Array = func_params.map(func(x): return x.name + ": " + x.type)
    var args_array: Array = func_params.map(func(x): return x.name)
    var params_string: String = ", ".join(params_array)
    var args_string: String = ", ".join(args_array)
    return FUNC_TEMPLATE.replace(FUNC_NAME, func_name) \
                        .replace(FUNC_PARAMS, params_string) \
                        .replace(FUNC_ARGS, args_string)
