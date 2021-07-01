-- Written by Fesiug
-- But I stole the ConVars part from ArcCW :ujel:

local convars = {
	-- Damage
	["fes_ply2npc_mult"]		= { def	= 1,	desc = "Player to NPC damage" },
	["fes_npc2ply_mult"]		= { def	= 1,	desc = "NPC to Player damage" },
	["fes_gra2ply_mult"]		= { def	= 1,	desc = "Fall damage multiplier" },
	
	-- Health
	["fes_ply_health_max"]		= { def	= 100,	desc = "Player maximum health" },
	["fes_ply_health_start"]	= { def	= 100,	desc = "Player start health" },
	["fes_ply_armor_max"]		= { def	= 100,	desc = "Player maximum armor" },
	["fes_ply_armor_start"]		= { def	= 0,	desc = "Player start armor" },

	-- Player modifiers
	["fes_plyspeed_duckenter"]		= { def	= 0.1,	desc = "Player duck enter speed" },
	["fes_plyspeed_duckexit"]		= { def	= 0.1,	desc = "Player duck exit speed" },
	["fes_plyspeed_walkslow"]		= { def	= 100,	desc = "Player +walk speed" },
	["fes_plyspeed_crouchedmult"]	= { def	= 0.3,	desc = "Player crouched speed mult" },
	["fes_plyspeed_ladder"]			= { def	= 200,	desc = "Player ladder climb speed" },
	["fes_plyspeed_walk"]			= { def	= 200,	desc = "Player normal walk speed" },
	["fes_plyspeed_run"]			= { def	= 400,	desc = "Player running speed" },
	["fes_plyspeed_jumppower"]		= { def	= 200,	desc = "Player jump power" },
	
	-- Player options
	["fes_plymod_collideteam"]		= { def	= 1,	desc = "Player to collide with teammates?" },
	["fes_plymod_avoidplayers"]		= { def	= 1,	desc = "Player squirms away from other players when haves no personal space?" },
	["fes_plymod_dmgindicator"]		= { def	= 0,	desc = "Disable the damage indicator?" },
	["fes_plymod_onlysprintforward"]	= { def	= 0,	desc = "Only allow players to sprint when moving forward, JUST LIKE MODERN WARFARE!!!" },
	
	["fes_ply_nohl2weps"]		= { def	= 0,	desc = "" },
}

for name, data in pairs(convars) do
	CreateConVar(name, data.def, FCVAR_ARCHIVE + FCVAR_REPLICATED, data.desc, data.min, data.max)
end

local function FES_GC( name, type )
	local returned = GetConVar(name)
	
	if type == "f" then
		returned = returned:GetFloat()
	elseif type == "i" then
		returned = returned:GetFloat()
	elseif type == "b" then
		returned = returned:GetBool()
	elseif type == "s" then
		returned = returned:GetString()
	end
	
	return returned
end

hook.Add( "EntityTakeDamage", "YouWillFuckNPCs", function( target, dmginfo )
	local dmg = dmginfo:GetDamage()
	local mult = 1
	
	if dmginfo:IsFallDamage() then
		mult = mult * FES_GC("fes_gra2ply_mult", "f")
	end
	
	if dmginfo:GetAttacker():IsNPC() and target and target:IsPlayer() then
		mult = mult * FES_GC("fes_npc2ply_mult", "f")
	end
	
	if target:IsNPC() and dmginfo:GetAttacker() and dmginfo:GetAttacker():IsPlayer() then
		mult = mult * FES_GC("fes_ply2npc_mult", "f")
	end
	
	dmginfo:SetDamage( dmg * mult )
end )

if SERVER then
	local function FES_Apply( ply )
		timer.Simple( 0, function()
			ply:SetHealth		( FES_GC("fes_ply_health_start",	"i") )
			ply:SetArmor		( FES_GC("fes_ply_armor_start",		"i") )
            ply:SetMaxHealth	( FES_GC("fes_ply_health_max",		"i") )
            ply:SetMaxArmor		( FES_GC("fes_ply_armor_max",		"i") )
			
            ply:SetDuckSpeed	( FES_GC("fes_plyspeed_duckenter",		"f") )
            ply:SetUnDuckSpeed	( FES_GC("fes_plyspeed_duckexit",		"f") )
            ply:SetSlowWalkSpeed	( FES_GC("fes_plyspeed_walkslow",	"f") )
            ply:SetWalkSpeed		( FES_GC("fes_plyspeed_walk",		"f") )
            ply:SetRunSpeed			( FES_GC("fes_plyspeed_run",		"f") )
            ply:SetLadderClimbSpeed		( FES_GC("fes_plyspeed_ladder",		"f") )
            ply:SetCrouchedWalkSpeed	( FES_GC("fes_plyspeed_crouchedmult",	"f") )
            ply:SetJumpPower			( FES_GC("fes_plyspeed_jumppower",		"f") )
			
            ply:SetNoCollideWithTeammates	( FES_GC("fes_plymod_collideteam",		"b") )
            ply:SetAvoidPlayers				( FES_GC("fes_plymod_avoidplayers",		"b") )
		end )
	end

    hook.Add( "PlayerSpawn", "FES_PlayerSpawn", FES_Apply )
    concommand.Add("fes_ply_apply", function()
        for i, v in ipairs( player.GetAll() ) do
            FES_Apply( v )
        end
    end )
	
	local fuckoff = {
		["weapon_357"] = true,
		["weapon_pistol"] = true,
		["weapon_smg1"] = true,
		["weapon_ar2"] = true,
		["weapon_shotgun"] = true,
		["weapon_rpg"] = true,
		["weapon_frag"] = true,
		["weapon_crossbow"] = true,
		["weapon_slam"] = true,
		["weapon_stunstick"] = true,
		["weapon_crowbar"] = true,
	}
	
	hook.Add( "PlayerCanPickupWeapon", "FES_ToggleWhen", function( ply, weapon )
		if GetConVar("fes_lockweps"):GetBool() and fuckoff[weapon:GetClass()] then	return false end
		--return !GetConVar("fes_lockweps"):GetBool()
	end )
end

hook.Add("StartCommand", "FES_SprintOnlyForward", function(ply, cmd)
	if FES_GC("fes_plymod_onlysprintforward", "b") and cmd:KeyDown( IN_SPEED ) and cmd:GetForwardMove() <= 0 then
		cmd:RemoveKey( IN_SPEED )
	end
end)