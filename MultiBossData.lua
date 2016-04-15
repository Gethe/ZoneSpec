local _, ZoneSpec = ...

local EJ_GetEncounterInfo = _G.EJ_GetEncounterInfo

ZoneSpec.multiBossAreas = { 
     -- Wrath dosn't have raid entries in the EJ yet, so we just hard code the name in until Legion.
    [543] = { -- Trial of the Crusader
        [1] = { -- Floor 1: The Argent Coliseum
            {
                left = 0,
                right = 1,
                top = 0,
                bottom = 1,
                key = "543-1-1",
                { -- Northrend Beasts
                    index = 1,
                    name = "Northrend Beasts",
                    encID = 1088,
                    npcID = {34796, 35144, 34799, 34797},
                },
                { -- Lord Jaraxxus
                    index = 2,
                    name = "Lord Jaraxxus",
                    encID = 1087,
                    npcID = {34780},
                },
                { -- Faction Champions
                    index = 3,
                    name = "Faction Champions",
                    encID = 1086,
                    npcID = {34458, 34451, 34459, 34448, 34449, 34445, 34456, 34447, 34441, 34454, 34444, 34455, 34450, 34453, 34461, 34460, 34469, 34467, 34468, 34471, 34465, 34466, 34473, 34472, 34470, 34463, 34474, 34475},
                },
                { -- Twin Val'kyr
                    index = 4,
                    name = "Twin Val'kyr",
                    encID = 1089,
                    npcID = {34497, 34496},
                    isLastBossforArea = true,
                },
            }
        }
    },
    [886] = { -- Terrace of Endless Spring 
        [0] = { 
            { 
                left = 0.67, 
                right = 1, 
                top = 0, 
                bottom = 1, 
                key = "886-0-1", 
                { -- Protectors of the Endless 
                    index = 1, 
                    name = EJ_GetEncounterInfo(683),
                    encID = 1409, 
                    npcID = {60583, 60586, 60585}, -- Protector Kaolan, Elder Asani, Elder Regail 
                }, 
                { -- Tsulong 
                    index = 2, 
                    name = EJ_GetEncounterInfo(742),
                    encID = 1505, 
                    npcID = {62442}, 
                    isLastBossforArea = true, 
                }, 
            }, 
            { 
                left = 0.51, 
                right = 0.67, 
                top = 0, 
                bottom = 1, 
                key = "886-0-2", 
                { -- Lei Shi 
                    index = 3, 
                    name = EJ_GetEncounterInfo(729),
                    encID = 1506, 
                    isLastBossforArea = true, 
                }, 
            }, 
            { 
                left = 0, 
                right = 0.51, 
                top = 0, 
                bottom = 1, 
                key = "886-0-3", 
                { -- Sha of Fear 
                    index = 4, 
                    name = EJ_GetEncounterInfo(709),
                    encID = 1431, 
                    isLastBossforArea = true, 
                }, 
            }, 
        } 
    }, 
    [1026] = { -- Hellfire Citadel 
        [1] = { -- Floor 1: The Iron Bulwark 
            { 
                left = 0, 
                right = 1, 
                top = 0, 
                bottom = 1, 
                key = "1026-1-1", 
                { -- Hellfire Assault 
                    index = 1, 
                    name = EJ_GetEncounterInfo(1426),
                    encID = 1778, 
                    npcID = {95068}, 
                }, 
                { -- Iron Reaver 
                    index = 2, 
                    name = EJ_GetEncounterInfo(1425),
                    encID = 1785, 
                    npcID = {90284}, 
                    isLastBossforArea = true, 
                }, 
            } 
        } 
    }, 
} 
