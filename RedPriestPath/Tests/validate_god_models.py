#!/usr/bin/env python3
"""Static gate for the Phase 10 seven-mist-deities cooked art package."""
from __future__ import annotations

import hashlib
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art/LOTMGodModels"
EXPECTED = {
    "UNIT_LOTM_RESCUE_GOD_FOOL": "LOTM_Fool",
    "UNIT_LOTM_RESCUE_GOD_NIGHT": "LOTM_Night",
    "UNIT_LOTM_RESCUE_GOD_STORM": "LOTM_Storm",
    "UNIT_LOTM_RESCUE_GOD_RED_PRIEST": "LOTM_RedPriest",
    "UNIT_LOTM_RESCUE_GOD_PERFECT": "LOTM_Perfect",
    "UNIT_LOTM_RESCUE_GOD_THIEF": "LOTM_Perfect",
    "UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR": "LOTM_BlackEmperor",
    "UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR": "LOTM_OuterGod",
    "UNIT_LOTM_RESCUE_OUTER_GOD_MINION": "LOTM_OuterGod",
}
EXPECTED_NO_OWNER_TINT_BLP_SHA256 = "27831ceb7ad11f65b7f9e06ab0b3f350e07ce975b689d7040ec6363270de85e1"
LAYERS = ("Body", "Accent", "Glow")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def named_elements(root: ET.Element, collection_name: str) -> dict[str, ET.Element]:
    for collection in root.findall("./m_RootCollections/Element"):
        name = collection.find("m_CollectionName")
        if name is not None and name.get("text") == collection_name:
            return {
                node.get("text"): element
                for element in collection.findall("./Element")
                if (node := element.find("m_Name")) is not None
            }
    raise AssertionError(f"missing collection {collection_name}")


def main() -> int:
    modinfo = ET.parse(ROOT / "RedPriestPath.modinfo").getroot()
    actions = {
        action.get("id"): action
        for action in modinfo.findall("./InGameActions/UpdateArt")
    }
    action = actions["LOTM_RESCUE_PHASE10_ART"]
    assert action.get("criteria") == "LOTM_RP_RESCUE_MODE"
    assert action.findtext("File") == "Art/LOTMGodModels/LOTMGodModels.dep"

    declared = {node.text for node in modinfo.findall("./Files/File")}
    required = {
        "Art/LOTMGodModels/LOTMGodModels.dep",
        "Art/LOTMGodModels/ArtDefs/Unit_Bins.artdef",
        "Art/LOTMGodModels/ArtDefs/Units.artdef",
        "Art/LOTMGodModels/Platforms/Windows/BLPs/LOTMGodModels.blp",
        "Art/LOTMGodModels/Platforms/MacOS/BLPs/LOTMGodModels.blp",
    }
    assert required <= declared, sorted(required - declared)

    windows = ART / "Platforms/Windows/BLPs/LOTMGodModels.blp"
    macos = ART / "Platforms/MacOS/BLPs/LOTMGodModels.blp"
    assert windows.stat().st_size > 1_000_000
    assert macos.stat().st_size > 1_000_000
    assert sha256(windows) == sha256(macos)
    assert sha256(windows) == EXPECTED_NO_OWNER_TINT_BLP_SHA256

    # The three church gods share the Free Cities owner.  Their cooked Unit
    # materials must pair each distinct BaseColor with the black no-tint mask;
    # otherwise Civ6 recolours every cloud with the same owner blue.
    blp = windows.read_bytes()
    for member_name in set(EXPECTED.values()):
        slug = member_name.removeprefix("LOTM_")
        assert blp.count(member_name.encode("ascii")) >= 4, member_name
        for layer in LAYERS:
            composite = (
                f"TEXTURE_DiffuseTint_LOTM_{slug}_{layer}_BaseColor_"
                "LOTM_Gods_TintMask"
            ).encode("ascii")
            assert composite in blp, composite

    dep_text = (ART / "LOTMGodModels.dep").read_text(encoding="utf-8")
    for token in ("Expansion2", "Unit_Bins.artdef", "Units.artdef", "LOTMGodModels.blp"):
        assert token in dep_text

    root = ET.parse(ART / "ArtDefs/Units.artdef").getroot()
    units = named_elements(root, "Units")
    members = named_elements(root, "UnitMemberTypes")
    assert set(EXPECTED) <= set(units)
    assert set(EXPECTED.values()) <= set(members)
    for unit_name, member_name in EXPECTED.items():
        type_refs = [
            node.find("m_ElementName").get("text")
            for node in units[unit_name].findall(".//Element")
            if (param := node.find("m_ParamName")) is not None
            and param.get("text") == "Type"
        ]
        assert type_refs == [member_name], (unit_name, type_refs)

    bins_text = (ART / "ArtDefs/Unit_Bins.artdef").read_text(encoding="utf-8")
    for member_name in set(EXPECTED.values()):
        slug = member_name.removeprefix("LOTM_")
        assert f'<m_Name text="LOTMGodModels_{slug}"' in bins_text
        assert f'<m_EntryName text="{member_name}"' in bins_text
        assert f'<m_Name text="{slug}"' in bins_text
    minion_scales = [
        node.find("m_fValue").text
        for node in units["UNIT_LOTM_RESCUE_OUTER_GOD_MINION"].findall(".//Element")
        if (param := node.find("m_ParamName")) is not None
        and param.get("text") == "Scale"
    ]
    assert "0.450000" in minion_scales
    print("Phase 10 god-model art validation passed.")
    print(f"BLP bytes: {windows.stat().st_size}")
    print(f"BLP SHA256: {sha256(windows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
