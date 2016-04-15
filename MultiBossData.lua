local _, ZoneSpec = ...

ZoneSpec.multiBossAreas = { 
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
                    ejID = 683, 
                    encID = 1409, 
                    npcID = {60583, 60586, 60585}, -- Protector Kaolan, Elder Asani, Elder Regail 
                }, 
                { -- Tsulong 
                    index = 2, 
                    ejID = 742, 
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
                    ejID = 729, 
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
                    ejID = 709, 
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
                    ejID = 1426, 
                    encID = 1778, 
                    npcID = {95068}, 
                }, 
                { -- Iron Reaver 
                    index = 2, 
                    ejID = 1425, 
                    encID = 1785, 
                    npcID = {90284}, 
                    isLastBossforArea = true, 
                }, 
            } 
        } 
    }, 
} 
