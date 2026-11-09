local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('BugSack', function()
	-- BugSack/sack.lua:215 crea el marco desde OpenSack/OpenConfig (:617,634).
	K:WatchAddonFrame('BugSack', 'BugSackFrame')
end)
