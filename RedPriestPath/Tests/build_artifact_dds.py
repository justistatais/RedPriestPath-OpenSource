from pathlib import Path
from PIL import Image

SOURCE = Path(r"C:\Users\20594\Downloads\tupian")
OUTPUT = Path(__file__).resolve().parents[1] / "Art" / "Artifacts"
OUTPUT.mkdir(parents=True, exist_ok=True)
DDS_OUTPUT = OUTPUT.parent

ARTIFACTS = {
    "黄金鉴定镜": "LOTM_ART_PP_GOLDEN_APPRAISAL_MIRROR",
    "永动齿轮箱": "LOTM_ART_PP_PERPETUAL_GEARBOX",
    "错误星盘": "LOTM_ART_PP_ERROR_ASTROLABE",
    "赫尔墨斯熔炉": "LOTM_ART_PP_HERMES_FURNACE",
    "奥秘结构图": "LOTM_ART_PP_MYSTERY_BLUEPRINT",
    "知识之门": "LOTM_ART_PP_KNOWLEDGE_CASKET",
    "文明启蒙碑": "LOTM_ART_PP_CIVILIZATION_STELE",
    "灾炎余烬": "LOTM_ART_RP_DISASTER_EMBER",
    "阴谋家的密信": "LOTM_ART_RP_CONSPIRATOR_LETTER",
    "嗜血收割镰": "LOTM_ART_RP_BLOOD_HARVEST_SICKLE",
    "铁血军旗": "LOTM_ART_RP_IRONBLOOD_BANNER",
    "战争圣典": "LOTM_ART_RP_WAR_SCRIPTURE",
    "灾厄气象仪": "LOTM_ART_RP_DISASTER_WEATHER",
    "征服者遗冠": "LOTM_ART_RP_CONQUEROR_CROWN",
    "黄金贿赂契约": "LOTM_ART_BE_GOLDEN_BRIBE",
    "腐化税册": "LOTM_ART_BE_CORRUPTION_TAXBOOK",
    "混乱法典残页": "LOTM_ART_BE_CHAOS_CODEX",
    "堕落盛宴": "LOTM_ART_BE_DEPRAVED_FEAST",
    "狂乱权杖": "LOTM_ART_BE_FRENZY_SCEPTER",
    "熵流王冠": "LOTM_ART_BE_ENTROPY_CROWN",
    "秩序转化器": "LOTM_ART_BE_ORDER_CONVERTER",
}
GREATWORK_TYPES = {
    "LOTM_ART_PP_GOLDEN_APPRAISAL_MIRROR": "GREATWORK_LOTM_PP_GOLDEN_APPRAISAL_MIRROR",
    "LOTM_ART_PP_PERPETUAL_GEARBOX": "GREATWORK_LOTM_PP_PERPETUAL_GEARBOX",
    "LOTM_ART_PP_ERROR_ASTROLABE": "GREATWORK_LOTM_PP_ERROR_ASTROLABE",
    "LOTM_ART_PP_HERMES_FURNACE": "GREATWORK_LOTM_PP_HERMES_FURNACE",
    "LOTM_ART_PP_MYSTERY_BLUEPRINT": "GREATWORK_LOTM_PP_MYSTERY_BLUEPRINT",
    "LOTM_ART_PP_KNOWLEDGE_CASKET": "GREATWORK_LOTM_PP_KNOWLEDGE_CASKET",
    "LOTM_ART_PP_CIVILIZATION_STELE": "GREATWORK_LOTM_PP_CIVILIZATION_STELE",
    "LOTM_ART_RP_DISASTER_EMBER": "GREATWORK_LOTM_RP_DISASTER_EMBER",
    "LOTM_ART_RP_CONSPIRATOR_LETTER": "GREATWORK_LOTM_RP_CONSPIRATOR_LETTER",
    "LOTM_ART_RP_BLOOD_HARVEST_SICKLE": "GREATWORK_LOTM_RP_BLOOD_HARVEST_SICKLE",
    "LOTM_ART_RP_IRONBLOOD_BANNER": "GREATWORK_LOTM_RP_IRONBLOOD_BANNER",
    "LOTM_ART_RP_WAR_SCRIPTURE": "GREATWORK_LOTM_RP_WAR_SCRIPTURE",
    "LOTM_ART_RP_DISASTER_WEATHER": "GREATWORK_LOTM_RP_DISASTER_WEATHER",
    "LOTM_ART_RP_CONQUEROR_CROWN": "GREATWORK_LOTM_RP_CONQUEROR_CROWN",
    "LOTM_ART_BE_GOLDEN_BRIBE": "GREATWORK_LOTM_BE_GOLDEN_BRIBE",
    "LOTM_ART_BE_CORRUPTION_TAXBOOK": "GREATWORK_LOTM_BE_CORRUPTION_TAXBOOK",
    "LOTM_ART_BE_CHAOS_CODEX": "GREATWORK_LOTM_BE_CHAOS_CODEX",
    "LOTM_ART_BE_DEPRAVED_FEAST": "GREATWORK_LOTM_BE_DEPRAVED_FEAST",
    "LOTM_ART_BE_FRENZY_SCEPTER": "GREATWORK_LOTM_BE_FRENZY_SCEPTER",
    "LOTM_ART_BE_ENTROPY_CROWN": "GREATWORK_LOTM_BE_ENTROPY_CROWN",
    "LOTM_ART_BE_ORDER_CONVERTER": "GREATWORK_LOTM_BE_ORDER_CONVERTER",
}

def render_contained(image: Image.Image, size: int) -> Image.Image:
    """Fit the complete source into a square atlas cell without cropping."""
    usable = max(1, round(size * 0.90))
    fitted = image.copy()
    fitted.thumbnail((usable, usable), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        fitted,
        ((size - fitted.width) // 2, (size - fitted.height) // 2),
    )
    return canvas


for chinese_name, asset_name in ARTIFACTS.items():
    image = Image.open(SOURCE / f"{chinese_name}.png").convert("RGBA")
    for size in (45, 64, 256):
        rendered = render_contained(image, size)
        filename = f"{asset_name}_{size}.dds"
        rendered.save(DDS_OUTPUT / filename, format="DDS", pixel_format="DXT5")
        rendered.save(OUTPUT / filename, format="DDS", pixel_format="DXT5")

atlas_rows = []
texture_rows = []
definition_rows = []
for asset_name, greatwork_type in GREATWORK_TYPES.items():
    atlas = f"ICON_ATLAS_{asset_name}"
    atlas_rows.append(f'\t\t<Row Name="{atlas}"/>')
    for size in (45, 64, 256):
        texture_rows.append(f'\t\t<Row Name="{atlas}" IconSize="{size}" IconsPerRow="1" IconsPerColumn="1" Filename="{asset_name}_{size}.dds"/>')
    definition_rows.append(f'\t\t<Row Name="ICON_{greatwork_type}" Atlas="{atlas}" Index="0"/>')

atlas_rows.append('\t\t<Row Name="ICON_ATLAS_LOTM_ARTIFACT_LAUNCH"/>')
for size in (40, 64, 256):
    texture_rows.append(
        f'\t\t<Row Name="ICON_ATLAS_LOTM_ARTIFACT_LAUNCH" IconSize="{size}" '
        f'IconsPerRow="1" IconsPerColumn="1" Filename="LOTM_ArtifactLaunchIcon{size}.dds"/>'
    )
definition_rows.append(
    '\t\t<Row Name="ICON_LOTM_ARTIFACT_LAUNCH" '
    'Atlas="ICON_ATLAS_LOTM_ARTIFACT_LAUNCH" Index="0"/>'
)

icon_xml = "\n".join([
    '<?xml version="1.0" encoding="utf-8"?>', '<GameInfo>', '\t<IconAtlases>', *atlas_rows,
    '\t</IconAtlases>', '\t<IconTextureAtlases>', *texture_rows, '\t</IconTextureAtlases>',
    '\t<IconDefinitions>', *definition_rows, '\t</IconDefinitions>', '</GameInfo>', ''
])
(OUTPUT.parent / "LOTM_Artifact_Icons.xml").write_text(icon_xml, encoding="utf-8")
print(f"generated {len(ARTIFACTS) * 3} DXT5 DDS files and artifact icon atlas")
