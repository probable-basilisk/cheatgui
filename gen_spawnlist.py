import os
import sys
import re

ITEM_NAME_PATT = re.compile(r'item_name\s*=\s*"([^"]*)"')

def find_item_name(raw_xml):
    """Finds the `item_name` out of an XML

    We don't use a real XML library because Noita's XML files are 
    non-standard. Instead we just regex search for this key-value pair
    like naive CS students.
    """
    match = ITEM_NAME_PATT.search(raw_xml)
    if match is None:
        return None
    return match.groups()[0]

def add_item(item_list, filename, subpath):
    # assume everything spawnable is an XML
    if filename[-4:].lower() != ".xml":
        return
    with open(filename, "rt") as src:
        data = src.read()
    ui_name = find_item_name(data)
    raw_name = os.path.split(filename)[-1]
    if ui_name is None:
        ui_name = raw_name
    item_list.append((subpath, ui_name, raw_name))

def find_items(rootdir, prefix=""):
    all_items = []
    for root, _, files in os.walk(rootdir):
        for fname in files:
            fullpath = os.path.join(root, fname)
            subpath = prefix + fullpath.replace(rootdir, "").replace("\\", "/")
            add_item(all_items, fullpath, subpath)
    return all_items

def escape_quotes(s):
    """Escape single quotes

    I'm not sure any Noita item names actually use single quotes, but better
    safe than sorry
    """
    return s.replace("'", "\\'")

def item_to_lua(item):
    return f"{{path='{escape_quotes(item[0])}', name='{escape_quotes(item[1])}', xml='{item[2]}'}}"

def item_list_to_lua(item_list):
    body = ",\n  ".join(item_to_lua(item) for item in item_list)
    return "spawn_list = {\n  " + body + "\n}"

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        path = sys.argv[1]
    else:
        path = os.path.abspath(os.path.expandvars(r'%LOCALAPPDATA%/../LocalLow/Nolla_Games_Noita/data'))
    print("Using path to Noita data: ", path)
    items_path = os.path.join(path, "entities/items")
    print("Path to items: ", items_path)
    items = find_items(items_path, "data/entities/items")
    items = sorted(items) # sort by path I guess?
    print(f"Found {len(items)} items.")
    lua = """
-- AUTOGENERATED! DO NOT EDIT DIRECTLY!
-- RUN 'gen_spawnlist.py' TO REGENERATE! (requires unpacked data!)
-- MANUALLY ADD special items to 'special_spawnables.lua'!
""" + item_list_to_lua(items)
    with open("data/hax/spawnables.lua", "wt") as dest:
        dest.write(lua)