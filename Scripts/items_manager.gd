# AutoLoad: time_manager
# items_manager.gd
extends Node

signal item_added(item_name: String, icon: Texture2D)

var items: Array = []

func add_item(item_name: String, icon: Texture2D = null):
	items.append({
		"name": item_name,
		"icon": icon
	})
	
	item_added.emit(item_name, icon)

func get_items() -> Array:
	return items

func has_item(item_name: String) -> bool:
	for item in items:
		if item.name == item_name:
			return true
	return false

func get_save_data() -> Dictionary:
	return {"items": items}

func load_save_data(data: Dictionary):
	if "items" in data:
		items = data.items
		for item in items:
			item_added.emit(item.name, item.icon)
