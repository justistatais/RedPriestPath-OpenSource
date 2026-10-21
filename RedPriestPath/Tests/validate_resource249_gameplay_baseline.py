#!/usr/bin/env python3
"""Pin protected files through the resource-291 authority hardening."""

from hashlib import sha256
from pathlib import Path
# Content contracts use unchanged code; test_rc342_startup_trace tests raw diagnostics.
from generate_startup_trace import strip_trace

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    # The city sources remain pinned. Resource 372 explicitly replaces the
    # UI request bridge; its new hash and executed state-machine tests preserve
    # the city command while allowing READY-save restoration and catch-up.
    "Scripts/LOTM_RESCUE_Phase1.lua": "3f3c44f34b2c4ca773c1875c09a8011e4d36801d3425776055e07154d61dd048",
    "Scripts/LOTM_RESCUE_Phase2Test.lua": "9f75a5d3f8b5794033c4184e30a5572b5194a1ae2138c333320582a2b3212856",
    # Resource 393: quiet helper version only; bootstrap logic is unchanged.
    # Lua 5.1 compilation and the unchanged actual API sequence
    # against the resource-373 baseline is checked by test_rc342_ui_trace.py.
    "UI/LOTM_RESCUE_CityBootstrap.lua": "f507498a3793b82fe06f3719c0bce4187d1e281d3368e1f73b0cedbabf738718",
}

MONSTERS_RESOURCE_249_SHA256 = "7b6b7412c1da806fb235fe1a68930a4379359806b340067795606aa361b568d0"
MONSTERS_RESOURCE_291_SHA256 = "0a86cb2dfa7cdb3ce82d530be0e5897dbc6eb6f0e90c05e1e28029547821f973"
# Resource 292 adds only a single-player stale-city-lock recovery branch.
MONSTERS_RESOURCE_292_SHA256 = "32e758eb6cb4128e7bde9697d24f339fba1331cc0828c165b534daab8a82fd82"
# Resource 352 adds a rescue-only reflection hook to the otherwise locked
# monster script; normal-mode constants and behavior remain unchanged.
MONSTERS_RESOURCE_352_RESCUE_REFLECTION_SHA256 = "7853ef99c672c4bda630db854edd800d76a4da0afd7e74c177d99675e83a33d6"
# Resource 360 preserves every spawn constant/result while batching the
# rescue turn's repeated live-index reconciliation and baseline lookup.
MONSTERS_RESOURCE_360_BATCHED_RESCUE_SHA256 = "dc139640bb05837c0f8bc67606a71746716a2af719b327305d57bea1eb56f833"
# Resource 363 retains resource 362's rescue-only rate and remote-target
# behavior and adds a rescue-only blocked-path redeploy retry.
MONSTERS_RESOURCE_363_BLOCKED_REDEPLOY_SHA256 = "f34034eb06fe690556b308728a9c4536fcca41dd22d4f818852bc7f1bec7014c"
# Resource 364 preserves spawn counts and rates while allowing target-city
# territory and expanding deterministically from ring 5 through ring 12.
MONSTERS_RESOURCE_364_EXPANDING_REDEPLOY_SHA256 = "62214073cf67366593433c8637406a7d1ceabcd4916e15849959119b8adfef26"
# Resource 372 only delegates ability arithmetic to LOTM_Effects. The executed
# old/new caller comparison lives in validate_effects_runtime.py; all monster
# spawn/target/redeploy rules below remain protected.
MONSTERS_RESOURCE_372_SHARED_EFFECTS_SHA256 = "b96795e0972ecd46c74b0e174665bc260c8a2be71971b55fccd4682e2d8b7596"

MONSTERS_RESOURCE_381_EARLY_SEAL_SHA256 = "b52e9dfec40b03840ff4c6f51fad05ef073b540ef2decafcf97b9d14154a6d08"

failed = []
for relative, expected in EXPECTED.items():
    actual = sha256((ROOT / relative).read_bytes()).hexdigest()
    if actual != expected:
        failed.append(f"{relative}: expected {expected}, got {actual}")

monsters_path = ROOT / "Scripts/LOTM_WORLD_Monsters.lua"
monsters_hash = sha256(monsters_path.read_bytes()).hexdigest()
if monsters_hash not in {MONSTERS_RESOURCE_249_SHA256, MONSTERS_RESOURCE_291_SHA256, MONSTERS_RESOURCE_292_SHA256, MONSTERS_RESOURCE_352_RESCUE_REFLECTION_SHA256, MONSTERS_RESOURCE_360_BATCHED_RESCUE_SHA256, MONSTERS_RESOURCE_363_BLOCKED_REDEPLOY_SHA256, MONSTERS_RESOURCE_364_EXPANDING_REDEPLOY_SHA256, MONSTERS_RESOURCE_372_SHARED_EFFECTS_SHA256, MONSTERS_RESOURCE_381_EARLY_SEAL_SHA256}:
    failed.append(
        "Scripts/LOTM_WORLD_Monsters.lua: hash is neither the protected "
        f"resource-249 baseline ({MONSTERS_RESOURCE_249_SHA256}), resource-291 "
        f"authority revision ({MONSTERS_RESOURCE_291_SHA256}) or resource-292 "
        f"single-player revision ({MONSTERS_RESOURCE_292_SHA256}); got {monsters_hash}"
    )
elif monsters_hash in {MONSTERS_RESOURCE_364_EXPANDING_REDEPLOY_SHA256, MONSTERS_RESOURCE_372_SHARED_EFFECTS_SHA256, MONSTERS_RESOURCE_381_EARLY_SEAL_SHA256}:
    monsters_text = strip_trace(monsters_path.read_text(encoding="utf-8"))
    required_monster_contract = (
        "local TIER_CHANCE={[2]=30,[1]=30,[0]=30};",
        "local TIER_BONUS={[2]=15,[1]=25,[0]=35};",
        "local TIER_MOVES={[2]=3,[1]=4,[0]=4};",
        'local REDEPLOY_TARGET_MIN_DISTANCE=5;',
        'local REDEPLOY_TARGET_MAX_DISTANCE=12;',
        "LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(rawBurst",
        "RescueActive() or plot:GetContinentType()==source:GetContinentType()",
        "RedeployNearTarget(monster,destination,REDEPLOY_TARGET_MIN_DISTANCE,REDEPLOY_TARGET_MAX_DISTANCE,false,AITerritoryOwners())",
        "reason=REDEPLOY_COOLDOWN attack=false",
        "SaveActiveMonsterSerials(batch.ActiveSerials)",
    )
    for token in required_monster_contract:
        if token not in monsters_text:
            failed.append(
                "Scripts/LOTM_WORLD_Monsters.lua: resource-364 expanding "
                f"redeploy revision is missing contract token: {token}"
            )
elif monsters_hash == MONSTERS_RESOURCE_363_BLOCKED_REDEPLOY_SHA256:
    monsters_text = strip_trace(monsters_path.read_text(encoding="utf-8"))
    required_monster_contract = (
        "local TIER_CHANCE={[2]=30,[1]=30,[0]=30};",
        "local TIER_BONUS={[2]=15,[1]=25,[0]=35};",
        "local TIER_MOVES={[2]=3,[1]=4,[0]=4};",
        'local REDEPLOYED_TURN_PROPERTY="LOTM_WORLD_MONSTER_REDEPLOYED_TURN";',
        "LOTM_RESCUE_Phase5.ScaleMonsterSpawnCount(rawBurst",
        "RescueActive() or plot:GetContinentType()==source:GetContinentType()",
        "LOTM_RESCUE_SyncActions.RedeployNearTarget",
        "reason=REDEPLOY_COOLDOWN attack=false",
        "reason=BLOCKED_",
        "SaveActiveMonsterSerials(batch.ActiveSerials)",
    )
    for token in required_monster_contract:
        if token not in monsters_text:
            failed.append(
                "Scripts/LOTM_WORLD_Monsters.lua: resource-363 rescue-only "
                f"rate/redeploy revision is missing contract token: {token}"
            )
elif monsters_hash == MONSTERS_RESOURCE_360_BATCHED_RESCUE_SHA256:
    monsters_text = strip_trace(monsters_path.read_text(encoding="utf-8"))
    required_monster_contract = (
        "local TIER_CHANCE={[2]=30,[1]=30,[0]=30};",
        "local TIER_BONUS={[2]=15,[1]=25,[0]=35};",
        "local TIER_MOVES={[2]=3,[1]=4,[0]=4};",
        "local function TrySpawnOne(camp,sourceUnit,periodic,networkSourceOwner,batch)",
        "local batch={Live=live,Cap=MapCap(),Baseline=",
        "SaveActiveMonsterSerials(batch.ActiveSerials)",
        "for slot=1,attempts do",
    )
    for token in required_monster_contract:
        if token not in monsters_text:
            failed.append(
                "Scripts/LOTM_WORLD_Monsters.lua: resource-360 batched rescue "
                f"revision is missing contract token: {token}"
            )
elif monsters_hash == MONSTERS_RESOURCE_352_RESCUE_REFLECTION_SHA256:
    monsters_text = strip_trace(monsters_path.read_text(encoding="utf-8"))
    required_monster_contract = (
        "LOTM_RESCUE_Thief.ShouldReflectAttack",
        "REFLECTED_33PCT_DAMAGE_",
        "REFLECTED_33PCT_CITY_DAMAGE_",
        "LOTM_WORLD_MONSTER_ATTACK_SERIAL",
    )
    for token in required_monster_contract:
        if token not in monsters_text:
            failed.append(
                "Scripts/LOTM_WORLD_Monsters.lua: rescue reflection revision "
                f"is missing contract token: {token}"
            )
elif monsters_hash == MONSTERS_RESOURCE_291_SHA256:
    # Keep gameplay/balance behavior pinned while permitting only the reviewed
    # multiplayer capture/settlement additions.  These sentinels cover the
    # exact constants and the unchanged native combat/target path; the full
    # revision remains hash-pinned above.
    monsters_text = strip_trace(monsters_path.read_text(encoding="utf-8"))
    required_monster_contract = (
        "local TIER_CHANCE={[2]=30,[1]=30,[0]=30};",
        "local TIER_BONUS={[2]=15,[1]=25,[0]=35};",
        "local TIER_MOVES={[2]=3,[1]=4,[0]=4};",
        "local REWARD_GOLD_PER_ERA :number=500;",
        "function LOTM_WORLD_Monsters.TrySpawnFromWorkshopNetwork(camp,sourceOwnerID,eventToken)",
        "local networkRemovalQueue={};",
        'local MONSTER_SOURCE_CAMP_EPOCH="LOTM_WORLD_MONSTER_SOURCE_CAMP_EPOCH";',
        'Game.GetProperty(prefix.."TARGET_KIND")',
        'prefix.."TARGET_SERIAL"',
        "LOTM_MP_TurnSync.Add(OnTurn,\"WorldMonsters\");",
        "Events.UnitRemovedFromMap.Add(OnRemoved);",
        "GameEvents.OnCombatOccurred.Add(OnCombat);",
    )
    for token in required_monster_contract:
        if token not in monsters_text:
            failed.append(
                "Scripts/LOTM_WORLD_Monsters.lua: audited resource-291 "
                f"authority revision is missing contract token: {token}"
            )
elif monsters_hash == MONSTERS_RESOURCE_292_SHA256:
    monsters_text = strip_trace(monsters_path.read_text(encoding="utf-8"))
    required_monster_contract = (
        "reason==\"NO_PLOT\" and targetKind==\"AI_CITY\"",
        "NO_PLOT_SP_RESELECT",
        "not LOTM_MP_TurnSync.IsNetworkGame()",
    )
    for token in required_monster_contract:
        if token not in monsters_text:
            failed.append(
                "Scripts/LOTM_WORLD_Monsters.lua: resource-292 single-player "
                f"recovery contract is missing token: {token}"
            )

flag_ui = strip_trace((ROOT / "UI/LOTM_PP_UnitFlagManager.lua").read_text(encoding="utf-8"))
required = (
    "GameConfiguration.IsAnyMultiplayer",
    "pendingFlags",
    "Events.GameCoreEventPublishComplete.Add(FlushPendingFlags)",
    "if IS_NETWORK_MULTIPLAYER then return false; end",
)
for token in required:
    if token not in flag_ui:
        failed.append(f"missing UI isolation token: {token}")

if failed:
    print("FAILED: resource-249 Gameplay baseline isolation")
    for item in failed:
        print(" -", item)
    raise SystemExit(1)

print("PASS: protected city baseline and explicit resource-372 effect/UI revisions")
