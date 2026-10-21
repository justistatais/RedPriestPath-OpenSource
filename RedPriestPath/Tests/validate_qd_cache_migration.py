"""Run the real QD shim in Lua 5.1; this is not in-game MP validation."""

from pathlib import Path
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa.lua51 import LuaRuntime
except ModuleNotFoundError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime


SCRIPT = (ROOT / "Scripts/LOTM_QD_MultiplayerCompat.lua").read_text(
    encoding="utf-8-sig"
)
KEY = "LOTM_QD_LOCAL_CACHE_MIGRATION_VERSION"
EXPECTED_READS = ",".join(
    f"{player}:{key}"
    for player in (0, 2, 19, 62, 63)
    for key in ("QD_SELLABLE_DEALS", "QD_BUYABLE_DEALS")
)

HARNESS = r'''
assert(_VERSION=="Lua 5.1", "QD tests require Civilization VI compatible Lua 5.1")
print = function() end
stats = {
    playerLookups=0, playerReads=0, playerWrites=0, gameWrites=0,
    registryCalls=0, localPlayerCalls=0, invalidNativeCalls=0,
    lookupIDs={}, invalidLookups={}, readOrder={}, writeOrder={}
}
saved = {}
playerSaved = {[0]={}, [2]={}, [19]={}, [62]={}, [63]={}}
nilPlayerIDs = {}
registryIDs = {63,19,0,2,62,19,2}
GameConfiguration = {IsAnyMultiplayer=function() return NETWORK end}
Game = {
    GetProperty=function(key) return saved[key] end,
    SetProperty=function(key,value)
        stats.gameWrites=stats.gameWrites+1
        saved[key]=value
    end,
    GetLocalPlayer=function()
        stats.localPlayerCalls=stats.localPlayerCalls+1
        return LOCAL_PLAYER_ID
    end
}
Players = setmetatable({}, {__index=function(_, id)
    stats.playerLookups=stats.playerLookups+1
    stats.lookupIDs[#stats.lookupIDs+1]=id
    if nilPlayerIDs[id] then return nil end
    local properties=playerSaved[id]
    if properties==nil then
        -- An unused slot still yields a non-nil wrapper. A nil check or pcall
        -- must not hide the access: both lookup and native calls are recorded.
        stats.invalidLookups[#stats.invalidLookups+1]=id
        local function invalidNative()
            stats.invalidNativeCalls=stats.invalidNativeCalls+1
            error("INVALID_NATIVE_PLAYER_SENTINEL:"..tostring(id))
        end
        return {
            GetProperty=invalidNative, SetProperty=invalidNative,
            IsAlive=invalidNative, IsMajor=invalidNative, GetID=invalidNative
        }
    end
    return {
        GetProperty=function(_, key)
            stats.playerReads=stats.playerReads+1
            stats.readOrder[#stats.readOrder+1]=tostring(id)..":"..key
            return properties[key]
        end,
        SetProperty=function(_, key, value)
            stats.playerWrites=stats.playerWrites+1
            stats.writeOrder[#stats.writeOrder+1]=tostring(id)..":"..key
            properties[key]=value
        end,
        -- Player 2 has been eliminated, but its save properties still exist.
        IsAlive=function() return id~=2 end,
        GetID=function() return id end
    }
end})
function RegisteredIDs()
    stats.registryCalls=stats.registryCalls+1
    return registryIDs
end
PlayerManager = {
    GetAliveMajorIDs=function() return {0} end,
    GetWasEverAliveIDs=RegisteredIDs
}
local function Event()
    local handlers={}
    return {
        Add=function(handler) handlers[#handlers+1]=handler end,
        Fire=function(...) for _,handler in ipairs(handlers) do handler(...) end end,
        Count=function() return #handlers end
    }
end
function ResetContext()
    Events = {LoadGameViewStateDone=Event(), LoadScreenClose=Event()}
    GameEvents = {PlayerTurnStarted=Event()}
    ExposedMembers = {QD={CacheManager={}}}
    GameInfo = nil
end
function SeedEveryRegisteredPlayer()
    for _, id in ipairs({0,2,19,62,63}) do
        playerSaved[id].QD_SELLABLE_DEALS={legacy="sell"}
        playerSaved[id].QD_BUYABLE_DEALS={legacy="buy"}
        playerSaved[id].UNRELATED="keep:"..tostring(id)
    end
end
function AllRegisteredCachesCleared()
    for _, id in ipairs({0,2,19,62,63}) do
        local properties=playerSaved[id]
        if properties.QD_SELLABLE_DEALS~=nil or properties.QD_BUYABLE_DEALS~=nil
           or properties.UNRELATED~="keep:"..tostring(id) then
            return false
        end
    end
    return true
end
ResetContext()
'''


def runtime(network=True, local_player=0):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().NETWORK = network
    lua.globals().LOCAL_PLAYER_ID = local_player
    lua.execute(HARNESS)
    return lua


def assert_lua(lua, expression):
    assert lua.eval(expression), expression


def assert_safe(lua):
    assert_lua(lua, "#stats.invalidLookups==0 and stats.invalidNativeCalls==0")
    assert_lua(lua, "stats.localPlayerCalls==0")


def assert_completed(lua):
    assert_safe(lua)
    assert_lua(lua, f'saved["{KEY}"]==1 and stats.gameWrites==1')
    assert_lua(lua, "AllRegisteredCachesCleared()")


def test_registered_slots_order_and_reload():
    lua = runtime()
    lua.execute("SeedEveryRegisteredPlayer(); originalRegistry=table.concat(registryIDs, ',')")
    lua.execute(SCRIPT)
    lua.execute('''
        Events.LoadGameViewStateDone.Fire()
        Events.LoadScreenClose.Fire()
        local cache=ExposedMembers.QD.CacheManager
        cache.SetCachedDeals({offer=7},true)
        assert(cache.GetCachedDeals(true).offer==7)
        GameEvents.PlayerTurnStarted.Fire(2)
    ''')
    assert_lua(lua, "stats.playerLookups==0 and stats.registryCalls==0 and stats.gameWrites==0")
    lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
    assert_completed(lua)
    assert_lua(lua, "stats.registryCalls==1 and stats.playerReads==10 and stats.playerWrites==10")
    assert lua.eval("table.concat(stats.readOrder, ',')") == EXPECTED_READS
    assert lua.eval("table.concat(stats.writeOrder, ',')") == EXPECTED_READS
    assert_lua(lua, "table.concat(registryIDs, ',')==originalRegistry")

    lookups = lua.eval("stats.playerLookups")
    lua.execute('''
        for turn=1,5 do GameEvents.PlayerTurnStarted.Fire(0) end
        ExposedMembers.QD.CacheManager={}
        GameEvents.PlayerTurnStarted.Fire(0)
        assert(type(ExposedMembers.QD.CacheManager.SetCachedDeals)=="function")
        ResetContext()
    ''')
    lua.execute(SCRIPT)
    lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
    assert_completed(lua)
    assert_lua(lua, "stats.registryCalls==1 and stats.playerReads==10 and stats.playerWrites==10")
    assert lua.eval("stats.playerLookups") == lookups


def test_registry_order_and_peer_independence():
    snapshots = []
    for ids in ("{63,19,0,2,62,19,2}", "{0,2,19,62,63}", "{62,2,63,19,0,63}"):
        for has_manager in (False, True):
            for local_player in (0, 19):
                lua = runtime(local_player=local_player)
                lua.execute(f"registryIDs={ids}; SeedEveryRegisteredPlayer()")
                if not has_manager:
                    lua.execute("ExposedMembers={}")
                original = lua.eval("table.concat(registryIDs, ',')")
                lua.execute(SCRIPT)
                lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
                assert_completed(lua)
                assert lua.eval("table.concat(registryIDs, ',')") == original
                snapshots.append(lua.eval(f'''function()
                    return saved["{KEY}"], stats.registryCalls,
                        table.concat(stats.readOrder, ','), table.concat(stats.writeOrder, ',')
                end''')())
    assert all(snapshot == (1, 1, EXPECTED_READS, EXPECTED_READS) for snapshot in snapshots)


def test_missing_or_empty_registry_recovers():
    unavailable = (
        "PlayerManager.GetWasEverAliveIDs=nil",
        "registryIDs={}",
        "registryIDs=nil",
        "registryIDs=false",
        "registryIDs=42",
        'registryIDs="not a registry"',
    )
    for setup in unavailable:
        lua = runtime()
        lua.execute("SeedEveryRegisteredPlayer()")
        lua.execute(setup)
        lua.execute(SCRIPT)
        lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
        assert_safe(lua)
        assert_lua(lua, f'saved["{KEY}"]==nil and stats.gameWrites==0 and stats.playerLookups==0')
        lua.execute('''
            registryIDs={63,19,0,2,62}
            PlayerManager.GetWasEverAliveIDs=RegisteredIDs
            GameEvents.PlayerTurnStarted.Fire(0)
            GameEvents.PlayerTurnStarted.Fire(0)
        ''')
        assert_completed(lua)
        assert_lua(lua, "stats.playerReads==10 and stats.playerWrites==10")


def test_invalid_registry_ids_do_not_complete():
    for invalid_id in ("-1", "64", "0.5", '"20"', "true", "{}", "0/0", "math.huge"):
        lua = runtime()
        lua.execute(f"SeedEveryRegisteredPlayer(); registryIDs={{0,2,19,62,63,{invalid_id}}}")
        lua.execute(SCRIPT)
        lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
        assert_safe(lua)
        assert_lua(lua, f'saved["{KEY}"]==nil and stats.gameWrites==0')
        assert_lua(lua, "stats.playerReads==0 and stats.playerWrites==0")
        lua.execute("registryIDs={0,2,19,62,63}; GameEvents.PlayerTurnStarted.Fire(0)")
        assert_completed(lua)


def test_registered_player_temporarily_nil_recovers():
    lua = runtime()
    lua.execute("SeedEveryRegisteredPlayer(); nilPlayerIDs[2]=true")
    lua.execute(SCRIPT)
    lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
    assert_safe(lua)
    assert_lua(lua, f'saved["{KEY}"]==nil and stats.gameWrites==0')
    assert_lua(lua, "playerSaved[2].QD_SELLABLE_DEALS~=nil and playerSaved[2].QD_BUYABLE_DEALS~=nil")
    lua.execute("nilPlayerIDs[2]=nil; GameEvents.PlayerTurnStarted.Fire(0)")
    assert_completed(lua)


def test_no_qd_no_legacy_keys_still_migrates_once():
    lua = runtime()
    lua.execute("ExposedMembers={}")
    lua.execute(SCRIPT)
    lua.execute("GameEvents.PlayerTurnStarted.Fire(0); GameEvents.PlayerTurnStarted.Fire(0)")
    assert_safe(lua)
    assert_lua(lua, f'saved["{KEY}"]==1 and stats.gameWrites==1')
    assert_lua(lua, "stats.registryCalls==1 and stats.playerReads==10 and stats.playerWrites==0")
    lua.execute("ExposedMembers={QD={CacheManager={}}}; Events.LoadGameViewStateDone.Fire()")
    assert_lua(lua, 'type(ExposedMembers.QD.CacheManager.SetCachedDeals)=="function"')


def test_singleplayer_is_unchanged():
    lua = runtime(network=False)
    lua.execute("SeedEveryRegisteredPlayer()")
    lua.execute(SCRIPT)
    assert_lua(lua, "GameEvents.PlayerTurnStarted.Count()==0 and Events.LoadScreenClose.Count()==0")
    lua.execute("GameEvents.PlayerTurnStarted.Fire(0); Events.LoadGameViewStateDone.Fire()")
    assert_safe(lua)
    assert_lua(lua, "stats.registryCalls==0 and stats.playerLookups==0 and stats.playerWrites==0 and stats.gameWrites==0")
    assert_lua(lua, 'playerSaved[0].QD_SELLABLE_DEALS.legacy=="sell"')
    assert_lua(lua, "ExposedMembers.QD.CacheManager.SetCachedDeals==nil")


def test_fixed_rc343_reproduces_unused_slot_20():
    # A positive control against the actual released failure prevents a safe
    # mock from concealing native-wrapper accesses as the earlier nil mock did.
    archive = ROOT.parent / "dist" / "RedPriestPath-0.1.0-rc.343.zip"
    with zipfile.ZipFile(archive) as release:
        names = [
            name for name in release.namelist()
            if name.endswith("/Scripts/LOTM_QD_MultiplayerCompat.lua")
        ]
        assert len(names) == 1, names
        old_script = release.read(names[0]).decode("utf-8-sig")

    for previous_release, script in ((True, old_script), (False, SCRIPT)):
        lua = runtime()
        lua.execute('''
            registryIDs={}
            for id=0,19 do
                playerSaved[id]={QD_SELLABLE_DEALS={legacy=true}}
                registryIDs[#registryIDs+1]=id
            end
            registryIDs[#registryIDs+1]=62
            registryIDs[#registryIDs+1]=63
        ''')
        lua.execute(script)
        failure = None
        try:
            lua.execute("GameEvents.PlayerTurnStarted.Fire(0)")
        except Exception as error:
            failure = str(error)
        if previous_release:
            assert failure and "INVALID_NATIVE_PLAYER_SENTINEL:20" in failure, failure
            assert_lua(lua, "#stats.invalidLookups==1 and stats.invalidLookups[1]==20")
            assert_lua(lua, "stats.invalidNativeCalls==1")
            assert_lua(lua, f'saved["{KEY}"]==nil and stats.gameWrites==0')
        else:
            assert failure is None, failure
            assert_safe(lua)
            assert_lua(lua, f'saved["{KEY}"]==1 and stats.gameWrites==1')
            assert_lua(lua, "stats.registryCalls==1 and stats.playerReads==44 and stats.playerWrites==20")


def main():
    tests = (
        test_registered_slots_order_and_reload,
        test_registry_order_and_peer_independence,
        test_missing_or_empty_registry_recovers,
        test_invalid_registry_ids_do_not_complete,
        test_registered_player_temporarily_nil_recovers,
        test_no_qd_no_legacy_keys_still_migrates_once,
        test_singleplayer_is_unchanged,
        test_fixed_rc343_reproduces_unused_slot_20,
    )
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS {len(tests)} real Lua 5.1 QD migration groups; game and two-client validation remain pending")


if __name__ == "__main__":
    main()
