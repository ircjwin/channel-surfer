extends Resource


# This will have the switchboard methods for a single channel
# Each method will have a double hash doc comment for params
# File needs written over for updates
# Must accept callback from surfer; Signal might work
# Surfer needs index for channel, index for method, and array of arg values

# How does channel index pass along?
# .tres files store their channel index?
# Resource name sent back to surfer?


signal switch_flipped(channel_switch: String, method_switch: String, param_switches: Array)


func todd(val: int, vol: bool, vil: String) -> void:
		switch_flipped.emit(resource_name, todd.get_method(), [val, vol, vil])
