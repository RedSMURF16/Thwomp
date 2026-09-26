/*
*
*	Thwomp by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /thwomp                     "Opens the Thwomp menu."
*       say_team /thwomp                "Opens the Thwomp menu."
*       thwomp_reload                   "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define THWOMP_KEY                  172714
#define THWOMP_ARRAY_ITEM           pev_iuser1
#define THWOMP_OWNER                pev_iuser1
#define THWOMP_SEQ_ANGRY            0
#define THWOMP_SEQ_SLEEP            1
#define THWOMP_TRIGGER_FACTOR       1.75
#define THWOMP_POINT_EPSILON        1.0
#define THWOMP_DEATH_PENALTY        5000.0
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 1.0
new const ERROR_FILE[]              = "Thwomp_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_THWOMP
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_SHAKE              = (1 << 0),

    FLAG_SHOW               = (1 << 1),
    FLAG_GHOST              = (1 << 2),
    FLAG_GROUND             = (1 << 3),
    FLAG_ACTIVE             = (1 << 4),
    FLAG_PENDING            = (1 << 5),
    FLAG_ANGRY              = (1 << 6),
    FLAG_IDLE               = (1 << 7),
    FLAG_RAISE              = (1 << 8),
    FLAG_SOUND_ALERT        = (1 << 9),
    FLAG_SOUND_SMASH        = (1 << 10)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SIZE_SMALL,
    SIZE_MEDIUM,
    SIZE_LARGE
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    Array:SETTING_DEFAULT_SOUND_ALERT,
    Array:SETTING_DEFAULT_SOUND_SMASH,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FALL_STRENGTH[2],
    Float:SETTING_DEFAULT_FALL_FREQ[2],
    Float:SETTING_DEFAULT_IDLE_DURATION[2],
    Float:SETTING_DEFAULT_RAISE_STRENGTH[2],
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_DEFAULT_SHAKE_DISTANCE,
    SETTING_DEFAULT_SHAKE_AMPLITUDE,
    SETTING_DEFAULT_SHAKE_FREQUENCY,
    SETTING_DEFAULT_SHAKE_DURATION,

    SETTING_MODEL_SMALL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_MEDIUM[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_LARGE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_SMALL[3],
    Float:SETTING_MAXS_SMALL[3],
    Float:SETTING_MINS_MEDIUM[3],
    Float:SETTING_MAXS_MEDIUM[3],
    Float:SETTING_MINS_LARGE[3],
    Float:SETTING_MAXS_LARGE[3],

    bool:SETTING_THWOMP_LOAD,
    Float:SETTING_THWOMP_CHECK,
    Float:SETTING_THWOMP_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP
}

enum _:THWOMP
{
    THWOMP_ID,
    THWOMP_ITEM,
    THWOMP_FLAGS,
    THWOMP_TEAM,
    THWOMP_SIZE,
    THWOMP_TRIGGER,
    THWOMP_NAME[MAX_VALUE_LENGTH],
    THWOMP_MODEL[MAX_RESOURCE_PATH_LENGTH],

    Float:THWOMP_ORIGIN_START[3],
    Float:THWOMP_ORIGIN_END[3],
    Float:THWOMP_ANGLES[3],
    Float:THWOMP_MINS[3],
    Float:THWOMP_MAXS[3],
    Float:THWOMP_DIRECTION[3],
    Array:THWOMP_SOUND_ALERT,
    Array:THWOMP_SOUND_SMASH,

    Float:THWOMP_FALL_STRENGTH[2],
    Float:THWOMP_FALL_FREQ[2],
    Float:THWOMP_IDLE_DURATION[2],
    Float:THWOMP_RAISE_STRENGTH[2],
    Float:THWOMP_COOLDOWN[2],
    Float:THWOMP_SHAKE_DISTANCE,
    THWOMP_SHAKE_AMPLITUDE,
    THWOMP_SHAKE_FREQUENCY,
    THWOMP_SHAKE_DURATION,

    Float:THWOMP_NEXT_COOLDOWN,
    Float:THWOMP_NEXT_FALL,
    Float:THWOMP_NEXT_RAISE
}

enum _:PLAYER_DATA
{
    PDATA_THWOMP_GHOST,
    PDATA_THWOMP_MENU,
    bool:PDATA_THWOMP_ACTION,
    PDATA_ROTATE_SIZE,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_SIZE,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "thwomp"

new Array:g_aThwomp,
    Array:g_aThwompConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdTouch, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iThwomp, g_iThwompConfig, g_iScreenShake,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateSize[][] = {"THWOMP_ROTATE_SMALL", "THWOMP_ROTATE_MEDIUM", "THWOMP_ROTATE_LARGE"}

public plugin_init()
{
    register_plugin("Thwomp", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_Thwomp", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /thwomp",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Thwomp menu.")
    register_clcmd("say_team /thwomp",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Thwomp menu.")
    register_concmd("thwomp_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("Thwomp.txt")

    g_iFwdTouch = RegisterHam(Ham_Touch, "info_target", "fwdTouch")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iScreenShake = get_user_msgid("ScreenShake")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableThwomp()

    thwompInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aThwomp = ArrayCreate(THWOMP)
    g_aThwompConfig = ArrayCreate(THWOMP)
    g_eSettings[SETTING_DEFAULT_SOUND_ALERT] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_SMASH] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aThwomp)
    ArrayDestroy(g_aThwompConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_ALERT])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_SMASH])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    thwompSound(id, SOUND_MENU_NAV)
    thwompMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    thwompReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id) )
                UpdateData(id)

        ArrayClear(g_aThwompConfig)
        g_iThwompConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/Thwomp.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eThwomp[THWOMP], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iThwompConfig )
                            ArrayPushArray(g_aThwompConfig, eThwomp)

                        copy(eThwomp[THWOMP_NAME], charsmax(eThwomp[THWOMP_NAME]), szData)
                        eThwomp[THWOMP_FLAGS]                   = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eThwomp[THWOMP_TEAM]                    = g_eSettings[SETTING_DEFAULT_TEAM]
                        eThwomp[THWOMP_FALL_STRENGTH][0]        = g_eSettings[SETTING_DEFAULT_FALL_STRENGTH][0]
                        eThwomp[THWOMP_FALL_STRENGTH][1]        = g_eSettings[SETTING_DEFAULT_FALL_STRENGTH][1]
                        eThwomp[THWOMP_FALL_FREQ][0]            = g_eSettings[SETTING_DEFAULT_FALL_FREQ][0]
                        eThwomp[THWOMP_FALL_FREQ][1]            = g_eSettings[SETTING_DEFAULT_FALL_FREQ][1]
                        eThwomp[THWOMP_IDLE_DURATION][0]        = g_eSettings[SETTING_DEFAULT_IDLE_DURATION][0]
                        eThwomp[THWOMP_IDLE_DURATION][1]        = g_eSettings[SETTING_DEFAULT_IDLE_DURATION][1]
                        eThwomp[THWOMP_RAISE_STRENGTH][0]       = g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH][0]
                        eThwomp[THWOMP_RAISE_STRENGTH][1]       = g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH][1]
                        eThwomp[THWOMP_COOLDOWN][0]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eThwomp[THWOMP_COOLDOWN][1]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]
                        eThwomp[THWOMP_SHAKE_DISTANCE]          = g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]
                        eThwomp[THWOMP_SHAKE_AMPLITUDE]         = g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]
                        eThwomp[THWOMP_SHAKE_FREQUENCY]         = g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]
                        eThwomp[THWOMP_SHAKE_DURATION]          = g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]
                        eThwomp[THWOMP_SOUND_ALERT]             = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND_ALERT])
                        eThwomp[THWOMP_SOUND_SMASH]             = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND_SMASH])

                        iSection = SECTION_THWOMP
                        g_iThwompConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_SOUND_ALERT") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_ALERT], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_ALERT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_SMASH") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_SMASH], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_SMASH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FALL_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FALL_STRENGTH], charsmax(g_eSettings[SETTING_DEFAULT_FALL_STRENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FALL_FREQ") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FALL_FREQ], charsmax(g_eSettings[SETTING_DEFAULT_FALL_FREQ]))
                        else if ( equali(szKey, "SETTING_DEFAULT_IDLE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_IDLE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_IDLE_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_RAISE_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH], charsmax(g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]))
                        else if ( equali(szKey, "SETTING_MODEL_SMALL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_SMALL], charsmax(g_eSettings[SETTING_MODEL_SMALL]))
                        else if ( equali(szKey, "SETTING_MODEL_MEDIUM") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_MEDIUM], charsmax(g_eSettings[SETTING_MODEL_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MODEL_LARGE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_LARGE], charsmax(g_eSettings[SETTING_MODEL_LARGE]))
                        else if ( equali(szKey, "SETTING_MINS_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_SMALL], charsmax(g_eSettings[SETTING_MINS_SMALL]))
                        else if ( equali(szKey, "SETTING_MAXS_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_SMALL], charsmax(g_eSettings[SETTING_MAXS_SMALL]))
                        else if ( equali(szKey, "SETTING_MINS_MEDIUM") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_MEDIUM], charsmax(g_eSettings[SETTING_MINS_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MAXS_MEDIUM") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_MEDIUM], charsmax(g_eSettings[SETTING_MAXS_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MINS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_LARGE], charsmax(g_eSettings[SETTING_MINS_LARGE]))
                        else if ( equali(szKey, "SETTING_MAXS_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_LARGE], charsmax(g_eSettings[SETTING_MAXS_LARGE]))
                        else if ( equali(szKey, "SETTING_THWOMP_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_THWOMP_LOAD], charsmax(g_eSettings[SETTING_THWOMP_LOAD]))
                        else if ( equali(szKey, "SETTING_THWOMP_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_THWOMP_CHECK], charsmax(g_eSettings[SETTING_THWOMP_CHECK]))
                        else if ( equali(szKey, "SETTING_THWOMP_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_THWOMP_TASK], charsmax(g_eSettings[SETTING_THWOMP_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                    }
                    case SECTION_THWOMP:
                    {
                        if ( equali(szKey, "THWOMP_SOUND_ALERT") )
                        {
                            if ( !(eThwomp[THWOMP_FLAGS] & FLAG_SOUND_ALERT) )
                            {
                                ArrayClear(eThwomp[THWOMP_SOUND_ALERT])
                                eThwomp[THWOMP_FLAGS] |= FLAG_SOUND_ALERT
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), eThwomp[THWOMP_SOUND_ALERT], charsmax(eThwomp[THWOMP_SOUND_ALERT]))
                        }
                        else if ( equali(szKey, "THWOMP_SOUND_SMASH") )
                        {
                            if ( !(eThwomp[THWOMP_FLAGS] & FLAG_SOUND_SMASH) )
                            {
                                ArrayClear(eThwomp[THWOMP_SOUND_SMASH])
                                eThwomp[THWOMP_FLAGS] |= FLAG_SOUND_SMASH
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), eThwomp[THWOMP_SOUND_SMASH], charsmax(eThwomp[THWOMP_SOUND_SMASH]))
                        }
                        else if ( equali(szKey, "THWOMP_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eThwomp[THWOMP_FLAGS], charsmax(eThwomp[THWOMP_FLAGS]))
                        else if ( equali(szKey, "THWOMP_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThwomp[THWOMP_TEAM], charsmax(eThwomp[THWOMP_TEAM]))
                        else if ( equali(szKey, "THWOMP_FALL_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThwomp[THWOMP_FALL_STRENGTH], charsmax(eThwomp[THWOMP_FALL_STRENGTH]))
                        else if ( equali(szKey, "THWOMP_FALL_FREQ") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThwomp[THWOMP_FALL_FREQ], charsmax(eThwomp[THWOMP_FALL_FREQ]))
                        else if ( equali(szKey, "THWOMP_IDLE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThwomp[THWOMP_IDLE_DURATION], charsmax(eThwomp[THWOMP_IDLE_DURATION]))
                        else if ( equali(szKey, "THWOMP_RAISE_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThwomp[THWOMP_RAISE_STRENGTH], charsmax(eThwomp[THWOMP_RAISE_STRENGTH]))
                        else if ( equali(szKey, "THWOMP_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThwomp[THWOMP_COOLDOWN], charsmax(eThwomp[THWOMP_COOLDOWN]))
                        else if ( equali(szKey, "THWOMP_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThwomp[THWOMP_SHAKE_DISTANCE], charsmax(eThwomp[THWOMP_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "THWOMP_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThwomp[THWOMP_SHAKE_AMPLITUDE], charsmax(eThwomp[THWOMP_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "THWOMP_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThwomp[THWOMP_SHAKE_FREQUENCY], charsmax(eThwomp[THWOMP_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "THWOMP_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThwomp[THWOMP_SHAKE_DURATION], charsmax(eThwomp[THWOMP_SHAKE_DURATION]))
                    }
                }
            }
        }
    }

    if ( g_iThwompConfig )
        ArrayPushArray(g_aThwompConfig, eThwomp)
    else
        set_fail_state("No Thwomps were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eThwomp[THWOMP], iItem
    if ( g_ePlayerData[id][PDATA_THWOMP_GHOST]
    && (iItem = thwompGet(eThwomp, g_ePlayerData[id][PDATA_THWOMP_GHOST])) != -1 )
    {
        thwompKill(eThwomp)
        thwompRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_THWOMP_GHOST]  = 0
    g_ePlayerData[id][PDATA_THWOMP_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock thwompInit()
{
    if ( g_eSettings[SETTING_THWOMP_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock thwompTerminate()
{
    new eThwomp[THWOMP]
    for ( new i = 0; i < g_iThwomp; i ++ )
    {
        ArrayGetArray(g_aThwomp, i, eThwomp)
        eThwomp[THWOMP_FLAGS] &= ~(FLAG_ANGRY | FLAG_IDLE | FLAG_RAISE)
        if ( !(eThwomp[THWOMP_FLAGS] & FLAG_PENDING) )
        {
            ArraySetArray(g_aThwomp, i, eThwomp)
            continue
        }

        eThwomp[THWOMP_FLAGS] |= FLAG_ACTIVE
        eThwomp[THWOMP_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aThwomp, i, eThwomp)
    }
}

stock thwompMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "THWOMP_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:         { menuRoot(id, iMenu); }
        case MENU_CREATE:       { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_ROOT_CREATE"); }
        case MENU_EDIT:         { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_ROOT_EDIT"); }
        case MENU_REMOVE:       { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_ROOT_REMOVE"); }
        case MENU_SHOW:         { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_ROOT_SHOW"); }
        case MENU_STATUS:       { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_ROOT_STATUS"); }
        case MENU_ROTATE:       { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "THWOMP_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROOT_NOCLIP", id, get_user_noclip(id) ? "THWOMP_ON" : "THWOMP_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROOT_GODMODE", id, get_user_godmode(id) ? "THWOMP_ON" : "THWOMP_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iThwomp >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_LIMIT", MAX_ENT)

                thwompSound(id, SOUND_MENU_REMOVE)
                thwompMenu(id, MENU_ROOT)
            }
            else
            {
                thwompSound(id, SOUND_MENU_NAV)
                thwompMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iThwomp )
            {
                client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_NO_THWOMP")

                thwompSound(id, SOUND_MENU_REMOVE)
                thwompMenu(id, MENU_ROOT)
            }
            else
            {
                thwompSound(id, SOUND_MENU_NAV)
                thwompMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iThwomp )
            {
                client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_NO_THWOMP")

                thwompSound(id, SOUND_MENU_REMOVE)
                thwompMenu(id, MENU_ROOT)
            }
            else
            {
                thwompSound(id, SOUND_MENU_REMOVE)
                thwompMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            thwompNoClip(id)
        }
        case ROOT_GODMODE:
        {
            thwompGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eThwomp[THWOMP], szItem[64]
    for ( new i = 0; i < g_iThwompConfig; i ++ )
    {
        ArrayGetArray(g_aThwompConfig, i, eThwomp)

        copy(szItem, charsmax(szItem), eThwomp[THWOMP_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        thwompSound(id, SOUND_MENU_NAV)
        thwompMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    thwompCreate(id, item)
    thwompSound(id, SOUND_MENU_NAV)
    thwompMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eThwomp[THWOMP]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_REMOVE_CURRENT", eThwomp[THWOMP_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    thwompSelect(eThwomp, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
}

public menuHandlerRemove(id, menu, item)
{
    new eThwomp[THWOMP]
    ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        thwompSelect(eThwomp, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THWOMP_MENU] >= g_iThwomp - 1 )
                g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THWOMP_MENU] ++

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THWOMP_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THWOMP_MENU] = g_iThwomp - 1
            else
                g_ePlayerData[id][PDATA_THWOMP_MENU] --

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eThwomp[THWOMP_FLAGS] &= ~FLAG_ACTIVE
            thwompSetState(eThwomp)
            thwompKill(eThwomp)
            thwompRemove(g_ePlayerData[id][PDATA_THWOMP_MENU])

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_REMOVE_CURRENT", eThwomp[THWOMP_NAME])
            g_ePlayerData[id][PDATA_THWOMP_MENU] = 0

            thwompSound(id, g_iThwomp > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            thwompMenu(id, g_iThwomp > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iThwomp )
            {
                ArrayGetArray(g_aThwomp, 0, eThwomp)
                eThwomp[THWOMP_FLAGS] &= ~FLAG_ACTIVE

                thwompSetState(eThwomp)
                thwompKill(eThwomp)
                thwompRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_THWOMP_MENU] = 0

            thwompSound(id, SOUND_MENU_ALERT)
            thwompMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                thwompSound(id, SOUND_MENU_NAV)
                thwompMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eThwomp[THWOMP]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_SHOW_CURRENT",
    eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? "\y" : "\r", eThwomp[THWOMP_NAME], id, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? "THWOMP_SHOWN" : "THWOMP_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    thwompSelect(eThwomp, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
}

public menuHandlerShow(id, menu, item)
{
    new eThwomp[THWOMP]
    ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        thwompSelect(eThwomp, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THWOMP_MENU] >= g_iThwomp - 1 )
                g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THWOMP_MENU] ++

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THWOMP_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THWOMP_MENU] = g_iThwomp - 1
            else
                g_ePlayerData[id][PDATA_THWOMP_MENU] --

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eThwomp[THWOMP_FLAGS] ^= FLAG_SHOW
            thwompSetState(eThwomp)

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_SHOW_CURRENT",
            eThwomp[THWOMP_NAME], id, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? "THWOMP_CHAT_SHOWN" : "THWOMP_CHAT_HIDDEN")
            ArraySetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iThwomp; i ++ )
            {
                ArrayGetArray(g_aThwomp, i, eThwomp)
                eThwomp[THWOMP_FLAGS] |= FLAG_SHOW
                thwompSetState(eThwomp)

                ArraySetArray(g_aThwomp, i, eThwomp)
            }

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_SHOW_ALL_SHOWN")
            thwompSound(id, SOUND_MENU_ALERT)
            thwompMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iThwomp; i ++ )
            {
                ArrayGetArray(g_aThwomp, i, eThwomp)
                eThwomp[THWOMP_FLAGS] &= ~FLAG_SHOW
                thwompSetState(eThwomp)

                ArraySetArray(g_aThwomp, i, eThwomp)
            }

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_SHOW_ALL_HIDDEN")
            thwompSound(id, SOUND_MENU_ALERT)
            thwompMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                thwompSound(id, SOUND_MENU_NAV)
                thwompMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eThwomp[THWOMP]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_STATUS_CURRENT",
    eThwomp[THWOMP_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eThwomp[THWOMP_NAME], id, eThwomp[THWOMP_FLAGS] & FLAG_ACTIVE ? "THWOMP_ENABLED" : "THWOMP_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    thwompSelect(eThwomp, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
}

public menuHandlerStatus(id, menu, item)
{
    new eThwomp[THWOMP]
    ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        thwompSelect(eThwomp, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THWOMP_MENU] >= g_iThwomp - 1 )
                g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THWOMP_MENU] ++

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THWOMP_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THWOMP_MENU] = g_iThwomp - 1
            else
                g_ePlayerData[id][PDATA_THWOMP_MENU] --

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eThwomp[THWOMP_FLAGS] ^= FLAG_ACTIVE
            thwompSetState(eThwomp)

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_STATUS_CURRENT",
            eThwomp[THWOMP_NAME], id, eThwomp[THWOMP_FLAGS] & FLAG_ACTIVE ? "THWOMP_CHAT_ENABLED" : "THWOMP_CHAT_DISABLED")
            ArraySetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iThwomp; i ++ )
            {
                ArrayGetArray(g_aThwomp, i, eThwomp)
                eThwomp[THWOMP_FLAGS] |= FLAG_ACTIVE
                thwompSetState(eThwomp)

                ArraySetArray(g_aThwomp, i, eThwomp)
            }

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_STATUS_ALL_ENABLED")
            thwompSound(id, SOUND_MENU_ALERT)
            thwompMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iThwomp; i ++ )
            {
                ArrayGetArray(g_aThwomp, i, eThwomp)
                eThwomp[THWOMP_FLAGS] &= ~FLAG_ACTIVE
                thwompSetState(eThwomp)

                ArraySetArray(g_aThwomp, i, eThwomp)
            }

            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_STATUS_ALL_DISABLED")
            thwompSound(id, SOUND_MENU_ALERT)
            thwompMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                thwompSound(id, SOUND_MENU_NAV)
                thwompMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THWOMP_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eThwomp[THWOMP]
    if ( thwompGet(eThwomp, g_ePlayerData[id][PDATA_THWOMP_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROTATE_GROUND",
    id, eThwomp[THWOMP_FLAGS] & FLAG_GROUND ? "THWOMP_ON" : "THWOMP_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THWOMP_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eThwomp[THWOMP], iItem
    if ( (iItem = thwompGet(eThwomp, g_ePlayerData[id][PDATA_THWOMP_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eThwomp[THWOMP_ID], pev_angles, eThwomp[THWOMP_ANGLES])
            eThwomp[THWOMP_ANGLES][1] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eThwomp[THWOMP_ANGLES][1] < -180.0 ) eThwomp[THWOMP_ANGLES][1] += 360.0

            set_pev(eThwomp[THWOMP_ID], pev_angles, eThwomp[THWOMP_ANGLES])
            ArraySetArray(g_aThwomp, iItem, eThwomp)

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eThwomp[THWOMP_ID], pev_angles, eThwomp[THWOMP_ANGLES])
            eThwomp[THWOMP_ANGLES][1] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eThwomp[THWOMP_ANGLES][1] > 180.0 ) eThwomp[THWOMP_ANGLES][1] -= 360.0

            set_pev(eThwomp[THWOMP_ID], pev_angles, eThwomp[THWOMP_ANGLES])
            ArraySetArray(g_aThwomp, iItem, eThwomp)

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eThwomp[THWOMP_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aThwomp, iItem, eThwomp)

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_ROTATE)
        }
        case ROTATE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_LARGE )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_SMALL

            eThwomp[THWOMP_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eThwomp[THWOMP_SIZE] )
            {
                case SIZE_SMALL:    engfunc(EngFunc_SetModel, eThwomp[THWOMP_ID], g_eSettings[SETTING_MODEL_SMALL])
                case SIZE_MEDIUM:   engfunc(EngFunc_SetModel, eThwomp[THWOMP_ID], g_eSettings[SETTING_MODEL_MEDIUM])
                case SIZE_LARGE:    engfunc(EngFunc_SetModel, eThwomp[THWOMP_ID], g_eSettings[SETTING_MODEL_LARGE])
            }

            ArraySetArray(g_aThwomp, iItem, eThwomp)
            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            thwompTrace(eThwomp, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THWOMP_GHOST] = 0

            eThwomp[THWOMP_FLAGS] &= ~FLAG_GHOST
            eThwomp[THWOMP_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eThwomp[THWOMP_ANGLES][0] = -eThwomp[THWOMP_ANGLES][0]
            thwompSetSize(eThwomp)
            thwompSetState(eThwomp)
            client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_CREATE_NEW", eThwomp[THWOMP_NAME])

            ArraySetArray(g_aThwomp, iItem, eThwomp)
            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            thwompKill(eThwomp)
            thwompRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THWOMP_GHOST] = 0

            thwompSound(id, SOUND_MENU_NAV)
            thwompMenu(id, MENU_CREATE)
        }
        default:
        {
            thwompKill(eThwomp)
            thwompRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THWOMP_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public thwompTask()
{
    new eThwomp[THWOMP], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iThwomp; i ++ )
    {
        ArrayGetArray(g_aThwomp, i, eThwomp)
        bModified = false

        if ( !(eThwomp[THWOMP_FLAGS] & FLAG_ANGRY)
        && eThwomp[THWOMP_FLAGS] & FLAG_RAISE )
        {
            new Float:fOrigin[3], Float:fPush[3]
            pev(eThwomp[THWOMP_ID], pev_origin, fOrigin)
            fPush[2] = random_float(eThwomp[THWOMP_RAISE_STRENGTH][0], eThwomp[THWOMP_RAISE_STRENGTH][1])
            set_pev(eThwomp[THWOMP_ID], pev_velocity, fPush)
            if ( fOrigin[2] >= eThwomp[THWOMP_ORIGIN_START][2] - THWOMP_POINT_EPSILON )
            {
                eThwomp[THWOMP_FLAGS] &= ~FLAG_RAISE
                set_pev(eThwomp[THWOMP_ID], pev_velocity, Float:{0.0, 0.0, 0.0})

                bModified = true
            }
        }

        if ( (eThwomp[THWOMP_FLAGS] & (FLAG_SHOW | FLAG_ACTIVE)) == (FLAG_SHOW | FLAG_ACTIVE) )
        {
            if ( eThwomp[THWOMP_FLAGS] & FLAG_ANGRY )
            {
                new Float:fOrigin[3]
                pev(eThwomp[THWOMP_ID], pev_origin, fOrigin)
                if ( fCurrentTime >= eThwomp[THWOMP_NEXT_FALL] )
                {
                    new Float:fVelocity[3]
                    pev(eThwomp[THWOMP_ID], pev_velocity, fVelocity)
                    fVelocity[2] -= random_float(eThwomp[THWOMP_FALL_STRENGTH][0], eThwomp[THWOMP_FALL_STRENGTH][1])
                    set_pev(eThwomp[THWOMP_ID], pev_velocity, fVelocity)
                    eThwomp[THWOMP_NEXT_FALL] = fCurrentTime + random_float(eThwomp[THWOMP_FALL_FREQ][0], eThwomp[THWOMP_FALL_FREQ][1])

                    bModified = true
                }

                if ( fOrigin[2] <= eThwomp[THWOMP_ORIGIN_END][2] + THWOMP_POINT_EPSILON )
                {
                    new szSound[MAX_RESOURCE_PATH_LENGTH]
                    ArrayGetString(eThwomp[THWOMP_SOUND_SMASH], random(ArraySize(eThwomp[THWOMP_SOUND_SMASH])), szSound, charsmax(szSound))
                    engfunc(EngFunc_EmitSound, eThwomp[THWOMP_ID], CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

                    eThwomp[THWOMP_FLAGS] &= ~FLAG_ANGRY
                    eThwomp[THWOMP_FLAGS] |= FLAG_IDLE
                    eThwomp[THWOMP_NEXT_RAISE] = fCurrentTime + random_float(eThwomp[THWOMP_IDLE_DURATION][0], eThwomp[THWOMP_IDLE_DURATION][1])
                    set_pev(eThwomp[THWOMP_ID], pev_velocity, Float:{0.0, 0.0, 0.0})
                    if ( eThwomp[THWOMP_FLAGS] & FLAG_SHAKE )
                        thwompShake(eThwomp)

                    bModified = true
                }
            }
            else if ( eThwomp[THWOMP_FLAGS] & FLAG_IDLE )
            {
                if ( fCurrentTime >= eThwomp[THWOMP_NEXT_RAISE] )
                {
                    eThwomp[THWOMP_FLAGS] &= ~FLAG_IDLE
                    eThwomp[THWOMP_FLAGS] |= FLAG_RAISE
                    eThwomp[THWOMP_NEXT_COOLDOWN] = fCurrentTime + random_float(eThwomp[THWOMP_COOLDOWN][0], eThwomp[THWOMP_COOLDOWN][1])
                    thwompSetSeq(eThwomp[THWOMP_ID], THWOMP_SEQ_SLEEP)

                    bModified = true
                }
            }
        }

        if ( bModified )
            ArraySetArray(g_aThwomp, i, eThwomp)
    }
}

stock thwompCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eThwomp[THWOMP]
    ArrayGetArray(g_aThwompConfig, iItem, eThwomp)
    eThwomp[THWOMP_ID] = iEnt
    eThwomp[THWOMP_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_THWOMP_GHOST] = eThwomp[THWOMP_ID]
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eThwomp[THWOMP_FLAGS] |= FLAG_GHOST
        eThwomp[THWOMP_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
    }

    thwompSelect(eThwomp, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, THWOMP_KEY)
    set_pev(iEnt, THWOMP_ARRAY_ITEM, g_iThwomp)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    switch( eThwomp[THWOMP_SIZE] )
    {
        case SIZE_SMALL:    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SMALL])
        case SIZE_MEDIUM:   engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_MEDIUM])
        case SIZE_LARGE:    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_LARGE])
    }

    ArrayPushArray(g_aThwomp, eThwomp)
    if ( ++ g_iThwomp == 1 )
    {
        set_task(g_eSettings[SETTING_THWOMP_TASK], "thwompTask", THWOMP_KEY, .flags = "b")
        EnableThwomp()
    }
}

stock thwompCreateTrigger(eThwomp[THWOMP])
{
    new iTrigger = cs_create_entity("info_target")
    if ( !pev_valid(iTrigger) )
    	return

    new Float:fStart[3], Float:fCenter[3], Float:fMins[3], Float:fMaxs[3], szCN[32]
    eThwomp[THWOMP_TRIGGER] = iTrigger
    formatex(szCN, charsmax(szCN), "%s_trigger", g_szCN)
    set_pev(iTrigger, THWOMP_OWNER, eThwomp[THWOMP_ID])
    set_pev(iTrigger, pev_classname, szCN)
    dllfunc(DLLFunc_Spawn, iTrigger)

    xs_vec_copy(eThwomp[THWOMP_ORIGIN_START], fStart)
    fStart[2] += eThwomp[THWOMP_MINS][2]

    xs_vec_sub(fStart, Float:{0.0, 0.0, 8192.0}, eThwomp[THWOMP_ORIGIN_END])
    engfunc(EngFunc_TraceLine, fStart, eThwomp[THWOMP_ORIGIN_END], IGNORE_MONSTERS, eThwomp[THWOMP_ID], 0)
    get_tr2(0, TR_vecEndPos, eThwomp[THWOMP_ORIGIN_END])

    xs_vec_copy(fStart, fCenter)
    fCenter[2] = (fStart[2] + eThwomp[THWOMP_ORIGIN_END][2]) * 0.5

    xs_vec_mul_scalar(eThwomp[THWOMP_MINS], THWOMP_TRIGGER_FACTOR, fMins)
    xs_vec_mul_scalar(eThwomp[THWOMP_MAXS], THWOMP_TRIGGER_FACTOR, fMaxs)
    fMins[2] = eThwomp[THWOMP_ORIGIN_END][2] - fCenter[2]
    fMaxs[2] = fStart[2] - fCenter[2]
    eThwomp[THWOMP_ORIGIN_END][2] += eThwomp[THWOMP_MAXS][2]

    engfunc(EngFunc_SetOrigin, iTrigger, fCenter)
    set_pev(iTrigger, pev_solid, SOLID_TRIGGER)
    set_pev(iTrigger, pev_movetype, MOVETYPE_NONE)
    engfunc(EngFunc_SetSize, iTrigger, fMins, fMaxs)
}

public thwompRemove(iItem)
{
    new eThwomp[THWOMP]
    ArrayDeleteItem(g_aThwomp, iItem)

    if ( -- g_iThwomp == 0 )
    {
        remove_task(THWOMP_KEY)
        DisableThwomp()
    }

    for ( new i = iItem; i < g_iThwomp; i ++ )
    {
        ArrayGetArray(g_aThwomp, i, eThwomp)
        set_pev(eThwomp[THWOMP_ID], THWOMP_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eThwomp[THWOMP],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Thwomp.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    thwompTerminate()
    for ( new i = 0; i < g_iThwomp; i ++ )
    {
        ArrayGetArray(g_aThwomp, i, eThwomp)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eThwomp[THWOMP_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eThwomp[THWOMP_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "size = %d^n", eThwomp[THWOMP_SIZE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eThwomp[THWOMP_ORIGIN_START][0], eThwomp[THWOMP_ORIGIN_START][1], eThwomp[THWOMP_ORIGIN_START][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eThwomp[THWOMP_ANGLES][0], eThwomp[THWOMP_ANGLES][1], eThwomp[THWOMP_ANGLES][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "direction = %.2f %.2f %.2f^n",
        eThwomp[THWOMP_DIRECTION][0], eThwomp[THWOMP_DIRECTION][1], eThwomp[THWOMP_DIRECTION][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "THWOMP_CHAT_TAG", id, "THWOMP_CHAT_SAVE", szFile)
    fclose(iFile)

    thwompSound(id, SOUND_MENU_NAV)
    thwompMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSize, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Thwomp.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataThwomp(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "size") )
            {
                iSize = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataThwomp(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataThwomp(iItem, iFlags, iSize, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eThwomp[THWOMP]
    thwompCreate(0, iItem)
    ArrayGetArray(g_aThwomp, iCount, eThwomp)

    eThwomp[THWOMP_FLAGS] = iFlags
    eThwomp[THWOMP_SIZE]  = iSize
    xs_vec_copy(fOrigin, eThwomp[THWOMP_ORIGIN_START])
    xs_vec_copy(fAngles, eThwomp[THWOMP_ANGLES])
    switch( eThwomp[THWOMP_SIZE] )
    {
        case SIZE_SMALL:    engfunc(EngFunc_SetModel, eThwomp[THWOMP_ID], g_eSettings[SETTING_MODEL_SMALL])
        case SIZE_MEDIUM:   engfunc(EngFunc_SetModel, eThwomp[THWOMP_ID], g_eSettings[SETTING_MODEL_MEDIUM])
        case SIZE_LARGE:    engfunc(EngFunc_SetModel, eThwomp[THWOMP_ID], g_eSettings[SETTING_MODEL_LARGE])
    }

    thwompSetBox(eThwomp)
    thwompSetSize(eThwomp)
    thwompSetState(eThwomp)
    thwompSetSeq(eThwomp[THWOMP_ID], THWOMP_SEQ_SLEEP)
    ArraySetArray(g_aThwomp, iCount, eThwomp)
}

public thwompNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    thwompSound(id, SOUND_MENU_NAV)
    thwompMenu(id, MENU_ROOT)
}

public thwompGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    thwompSound(id, SOUND_MENU_NAV)
    thwompMenu(id, MENU_ROOT)
}

public fwdTouch(iEnt, iOther)
{
    if ( !is_user_alive(iOther) )
        return HAM_IGNORED

    new iThwomp = iEnt
    if ( !isThwomp(iThwomp) )
        iThwomp = pev(iThwomp, THWOMP_OWNER)
    if ( !isThwomp(iThwomp) )
        return HAM_IGNORED

    new eThwomp[THWOMP], iItem
    if ( (iItem = thwompGet(eThwomp, iThwomp)) == -1
    || !(eThwomp[THWOMP_FLAGS] & FLAG_ACTIVE)
    || !(CsTeams:eThwomp[THWOMP_TEAM] & cs_get_user_team(iOther)) )
        return HAM_IGNORED

    new Float:fThwompOrigin[3], Float:fOrigin[3]
    pev(iThwomp, pev_origin, fThwompOrigin)
    pev(iOther, pev_origin, fOrigin)
    fThwompOrigin[2] += eThwomp[THWOMP_MINS][2]

    if ( iEnt == eThwomp[THWOMP_TRIGGER] )
    {
        if ( !(eThwomp[THWOMP_FLAGS] & (FLAG_ANGRY | FLAG_IDLE | FLAG_RAISE))
        && get_gametime() >= eThwomp[THWOMP_NEXT_COOLDOWN]
        && fOrigin[2] < fThwompOrigin[2] )
        {
            new szSound[MAX_RESOURCE_PATH_LENGTH]
            ArrayGetString(eThwomp[THWOMP_SOUND_ALERT], random(ArraySize(eThwomp[THWOMP_SOUND_ALERT])), szSound, charsmax(szSound))
            engfunc(EngFunc_EmitSound, eThwomp[THWOMP_ID], CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

            eThwomp[THWOMP_FLAGS] |= FLAG_ANGRY
            thwompSetSeq(eThwomp[THWOMP_ID], THWOMP_SEQ_ANGRY)
            ArraySetArray(g_aThwomp, iItem, eThwomp)
        }
    }
    else if ( eThwomp[THWOMP_FLAGS] & FLAG_ANGRY )
    {
        if ( fOrigin[2] < fThwompOrigin[2] )
            ExecuteHamB(Ham_TakeDamage, iOther, iThwomp, iThwomp, THWOMP_DEATH_PENALTY, DMG_ALWAYSGIB)
    }

    return HAM_IGNORED
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eThwomp[THWOMP], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( thwompGet(eThwomp, g_ePlayerData[id][PDATA_THWOMP_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_THWOMP_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            thwompTrace(eThwomp, id)
        }
        else if ( g_ePlayerData[id][PDATA_THWOMP_ACTION] )
        {
            thwompCheck(id)
        }
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_THWOMP_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_THWOMP_GHOST] )
    {
        new eThwomp[THWOMP], iItem
        if ( (iItem = thwompGet(eThwomp, g_ePlayerData[id][PDATA_THWOMP_GHOST])) != -1 )
        {
            thwompKill(eThwomp)
            thwompRemove(iItem)
        }

        g_ePlayerData[id][PDATA_THWOMP_GHOST] = 0
    }
}

stock thwompTrace(eThwomp[THWOMP], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eThwomp[THWOMP_ORIGIN_START])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eThwomp[THWOMP_ORIGIN_START], fVec1)

    engfunc(EngFunc_TraceLine, eThwomp[THWOMP_ORIGIN_START], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eThwomp[THWOMP_ORIGIN_START])

    thwompSetBox(eThwomp)
    thwompSetOffset(eThwomp)
    set_pev(eThwomp[THWOMP_ID], pev_origin, eThwomp[THWOMP_ORIGIN_START])
}

stock thwompCheck(id)
{
    new eThwomp[THWOMP], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_THWOMP_CHECK]
    for ( new i = 0; i < g_iThwomp; i ++ )
    {
        ArrayGetArray(g_aThwomp, i, eThwomp)
        xs_vec_sub(eThwomp[THWOMP_ORIGIN_START], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eThwomp[THWOMP_ID], pev_absmin, fMins)
        pev(eThwomp[THWOMP_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = xs_vec_distance(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_THWOMP_MENU] != iBest )
    {
        ArrayGetArray(g_aThwomp, g_ePlayerData[id][PDATA_THWOMP_MENU], eThwomp)
        thwompSelect(eThwomp, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_THWOMP_MENU] = iBest
        thwompMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock thwompShake(eThwomp[THWOMP])
{
    new Float:fOrigin[3]
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eThwomp[THWOMP_ORIGIN_END]) > eThwomp[THWOMP_SHAKE_DISTANCE] )
            continue

        message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
        write_short(eThwomp[THWOMP_SHAKE_AMPLITUDE] * 4096)
        write_short(eThwomp[THWOMP_SHAKE_DURATION] * 4096)
        write_short(eThwomp[THWOMP_SHAKE_FREQUENCY] * 4096)
        message_end()
    }
}

stock thwompSetBox(eThwomp[THWOMP])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eThwomp[THWOMP_ANGLES][0] = -eThwomp[THWOMP_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eThwomp[THWOMP_ANGLES], fForward, fRight, fUp)
    switch( eThwomp[THWOMP_SIZE] )
    {
        case SIZE_SMALL:    { xs_vec_copy(g_eSettings[SETTING_MINS_SMALL], fMins); xs_vec_copy(g_eSettings[SETTING_MAXS_SMALL], fMaxs); }
        case SIZE_MEDIUM:   { xs_vec_copy(g_eSettings[SETTING_MINS_MEDIUM], fMins); xs_vec_copy(g_eSettings[SETTING_MAXS_MEDIUM], fMaxs); }
        case SIZE_LARGE:    { xs_vec_copy(g_eSettings[SETTING_MINS_LARGE], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_LARGE], fMaxs); }
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eThwomp[THWOMP_MINS])
    xs_vec_copy(fMaxs, eThwomp[THWOMP_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] + fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] + fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] + fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock thwompSetOffset(eThwomp[THWOMP])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eThwomp[THWOMP_MINS][0]
    fGaps[1] = eThwomp[THWOMP_MAXS][0]
    fGaps[2] = -eThwomp[THWOMP_MINS][1]
    fGaps[3] = eThwomp[THWOMP_MAXS][1]
    fGaps[4] = -eThwomp[THWOMP_MINS][2]
    fGaps[5] = eThwomp[THWOMP_MAXS][2]

    if ( eThwomp[THWOMP_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eThwomp[THWOMP_ORIGIN_START], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eThwomp[THWOMP_ORIGIN_START], fVec1, DONT_IGNORE_MONSTERS, eThwomp[THWOMP_ID], 0)
        get_tr2(0, TR_vecEndPos, eThwomp[THWOMP_ORIGIN_START])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eThwomp[THWOMP_ORIGIN_START], fVec1)
        engfunc(EngFunc_TraceLine, eThwomp[THWOMP_ORIGIN_START], fVec1, DONT_IGNORE_MONSTERS, eThwomp[THWOMP_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eThwomp[THWOMP_ORIGIN_START], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eThwomp[THWOMP_ORIGIN_START], fVec1, eThwomp[THWOMP_ORIGIN_START])
        }
    }
}

stock thwompSetSeq(iEnt, iSequence)
{
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, 1.0)
    set_pev(iEnt, pev_animtime, get_gametime())
    set_pev(iEnt, pev_effects, pev(iEnt, pev_effects) | EF_NOINTERP)
}

stock thwompSetSize(eThwomp[THWOMP])
{
    thwompSelect(eThwomp, TARGET_CLEAR)
    thwompSetSeq(eThwomp[THWOMP_ID], THWOMP_SEQ_SLEEP)
    engfunc(EngFunc_SetOrigin, eThwomp[THWOMP_ID], eThwomp[THWOMP_ORIGIN_START])
    set_pev(eThwomp[THWOMP_ID], pev_angles, eThwomp[THWOMP_ANGLES])
    set_pev(eThwomp[THWOMP_ID], pev_solid, eThwomp[THWOMP_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eThwomp[THWOMP_ID], pev_movetype, MOVETYPE_FLY)

    eThwomp[THWOMP_ANGLES][0] = -eThwomp[THWOMP_ANGLES][0]
    engfunc(EngFunc_SetSize, eThwomp[THWOMP_ID], eThwomp[THWOMP_MINS], eThwomp[THWOMP_MAXS])
    engfunc(EngFunc_AngleVectors, eThwomp[THWOMP_ANGLES], NULL_VECTOR, NULL_VECTOR, eThwomp[THWOMP_DIRECTION])
    xs_vec_mul_scalar(eThwomp[THWOMP_DIRECTION], -1.0, eThwomp[THWOMP_DIRECTION])
    thwompCreateTrigger(eThwomp)
}

stock thwompSetState(eThwomp[THWOMP])
{
    if ( eThwomp[THWOMP_FLAGS] & FLAG_SHOW )
    {
        set_pev(eThwomp[THWOMP_ID], pev_solid, SOLID_BBOX)
        thwompSelect(eThwomp, TARGET_CLEAR)

        if ( !(eThwomp[THWOMP_FLAGS] & FLAG_ACTIVE) )
        {
            thwompSetSeq(eThwomp[THWOMP_ID], THWOMP_SEQ_SLEEP)

            if ( eThwomp[THWOMP_FLAGS] & FLAG_ANGRY )
            {
                eThwomp[THWOMP_FLAGS] &= ~FLAG_ANGRY
                eThwomp[THWOMP_FLAGS] |= FLAG_RAISE
            }
        }
    }
    else
    {
        set_pev(eThwomp[THWOMP_ID], pev_solid, SOLID_NOT)
        thwompSelect(eThwomp, TARGET_HIDE)
        thwompSetSeq(eThwomp[THWOMP_ID], THWOMP_SEQ_SLEEP)
        if ( eThwomp[THWOMP_FLAGS] & FLAG_ANGRY )
        {
            eThwomp[THWOMP_FLAGS] &= ~FLAG_ANGRY
            eThwomp[THWOMP_FLAGS] |= FLAG_RAISE
        }
    }
}

stock thwompSelect(eThwomp[THWOMP], iAction)
{
    new iRender, iRenderFx, iRenderColor[3], iRenderAmt

    iRenderFx = kRenderFxNone
    if ( iAction == TARGET_SELECT )
    {
        if ( eThwomp[THWOMP_FLAGS] & FLAG_ACTIVE )  { iRenderColor[0] = g_iColorActive[0];      iRenderColor[1] = g_iColorActive[1];     iRenderColor[2] = g_iColorActive[2]; }
        else                                        { iRenderColor[0] = g_iColorInactive[0];    iRenderColor[1] = g_iColorInactive[1];   iRenderColor[2] = g_iColorInactive[2]; }

        iRender = kRenderTransColor
        iRenderFx = kRenderFxGlowShell
        iRenderAmt = 16
    }
    else if ( iAction == TARGET_GHOST )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = g_eSettings[SETTING_GHOST_ALPHA]
    }
    else if ( iAction == TARGET_HIDE )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = 0
    }
    else if ( iAction == TARGET_CLEAR )
    {
        iRender = kRenderNormal
        iRenderAmt = 255
    }

    set_ent_rendering(eThwomp[THWOMP_ID], iRenderFx, iRenderColor[0], iRenderColor[1], iRenderColor[2], iRender, iRenderAmt)
}

stock thwompSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock thwompReset()
{
    new eThwomp[THWOMP]
    for ( new i = 0; i < g_iThwomp; i ++ )
    {
        ArrayGetArray(g_aThwomp, i, eThwomp)
        eThwomp[THWOMP_NEXT_COOLDOWN] = 0.0
        eThwomp[THWOMP_NEXT_FALL] = 0.0
        eThwomp[THWOMP_NEXT_RAISE] = 0.0
        ArraySetArray(g_aThwomp, i, eThwomp)
    }
}

stock thwompGet(eThwomp[THWOMP], iEnt)
{
    new iItem
    iItem = pev(iEnt, THWOMP_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iThwomp )
        return -1

    ArrayGetArray(g_aThwomp, iItem, eThwomp)
    return iItem
}

stock bool:isThwomp(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == THWOMP_KEY
}

stock thwompKill(eThwomp[THWOMP])
{
    if ( pev_valid(eThwomp[THWOMP_ID]) )
        set_pev(eThwomp[THWOMP_ID], pev_flags, pev(eThwomp[THWOMP_ID], pev_flags) | FL_KILLME)

    if ( pev_valid(eThwomp[THWOMP_TRIGGER]) )
        set_pev(eThwomp[THWOMP_TRIGGER], pev_flags, pev(eThwomp[THWOMP_TRIGGER], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_THWOMP_ACTION] )
    {
        new eThwomp[THWOMP]
        for ( new i = 0; i < g_iThwomp; i ++ )
        {
            ArrayGetArray(g_aThwomp, i, eThwomp)
            if ( eThwomp[THWOMP_FLAGS] & FLAG_SHOW )
                continue

            thwompSelect(eThwomp, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_THWOMP_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_THWOMP_ACTION] )
    {
        new eThwomp[THWOMP]
        for ( new i = 0; i < g_iThwomp; i ++ )
        {
            ArrayGetArray(g_aThwomp, i, eThwomp)
            if ( eThwomp[THWOMP_FLAGS] & FLAG_SHOW )
                continue

            thwompSelect(eThwomp, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_THWOMP_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock EnableThwomp()
{
    EnableHamForward(g_iFwdTouch)
}

stock DisableThwomp()
{
    DisableHamForward(g_iFwdTouch)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}