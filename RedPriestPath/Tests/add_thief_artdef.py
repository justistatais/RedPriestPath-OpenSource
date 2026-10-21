#!/usr/bin/env python3
"""Clone the established holder art entry for the Thief holder."""

from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

PATH = Path(__file__).resolve().parents[1] / "Art" / "LOTM_RP_Units.artdef"
SOURCE = "UNIT_LOTM_RP_PATH_HOLDER"
TARGET = "UNIT_LOTM_TP_PATH_HOLDER"

tree = ET.parse(PATH)
root = tree.getroot()
parent = {child: node for node in root.iter() for child in node}
source = target = None
for element in root.iter("Element"):
    name = element.find("./m_Name")
    if name is not None and name.get("text") == SOURCE:
        source = element
    if name is not None and name.get("text") == TARGET:
        target = element
if target is None:
    if source is None:
        raise SystemExit(f"missing source art entry: {SOURCE}")
    clone = deepcopy(source)
    clone.find("./m_Name").set("text", TARGET)
    container = parent[source]
    container.insert(list(container).index(source) + 1, clone)
    ET.indent(tree, space="\t")
    tree.write(PATH, encoding="UTF-8", xml_declaration=True)
    print(f"added {TARGET}")
else:
    print(f"already present: {TARGET}")
