-- Generado por tools/base/generar.lua: no editar a mano. Configuración del autor que difiere de lo que
-- arma "Aplicar todo" (melé, columnas, bloque derecho compacto). K:ApplyBase la pone sobre el diseño,
-- antes de las modificaciones por rol (Roles.lua) y por modo (Tanks.lua).
local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K.Base = {
	KnuUIRaidMarkers = "always",
	actionbar = {
		bar1 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontOutline = "OUTLINE",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar10 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar13 = {
			countFontSize = 15,
			hotkeyFontSize = 15,
			macroFontSize = 15,
		},
		bar14 = {
			countFontSize = 15,
			hotkeyFontSize = 15,
			macroFontSize = 15,
		},
		bar15 = {
			countFontSize = 15,
			hotkeyFontSize = 15,
			macroFontSize = 15,
		},
		bar2 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar3 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar4 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar5 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar6 = {
			countFont = "Expressway",
			countFontSize = 15,
			flyoutDirection = "LEFT",
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar7 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar8 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		bar9 = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			macroFont = "Expressway",
			macroFontSize = 15,
		},
		barPet = {
			countFont = "Expressway",
			countFontSize = 15,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			hotkeytext = false,
		},
		extraActionButton = {
			clean = true,
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			scale = 0.9,
		},
		font = "Expressway",
		fontOutline = "OUTLINE",
		fontSize = 15,
		stanceBar = {
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
			hotkeytext = false,
			style = "classic",
		},
		transparent = true,
		vehicleExitButton = {
			hotkeyFont = "Expressway",
			hotkeyFontSize = 15,
		},
		zoneActionButton = {
			clean = true,
		},
	},
	auras = {
		buffs = {
			barPosition = "RIGHT",
			barShow = true,
			barSize = 3,
			barSpacing = -1,
			countFont = "Expressway",
			countFontOutline = "OUTLINE",
			countFontSize = 14,
			sortDir = "+",
		},
		debuffs = {
			barColor = {
				b = 0.152941,
				g = 0.0627451,
				r = 0.941177,
			},
			barPosition = "RIGHT",
			barShow = true,
			barSize = 3,
			barSpacing = -1,
			countFont = "Expressway",
			countFontOutline = "NONE",
			countFontSize = 14,
		},
	},
	bags = {
		bagSize = 31,
		bagWidth = 553,
		bankSize = 31,
		bankWidth = 553,
		clearSearchOnClose = true,
		countFont = "Expressway",
		countFontOutline = "OUTLINE",
		countFontSize = 12,
		currencyFormat = "ICON",
		itemLevelFont = "Expressway",
		itemLevelFontOutline = "OUTLINE",
		itemLevelFontSize = 12,
		junkIcon = true,
		moneyFormat = "BLIZZARD2",
		scrapIcon = true,
		spinner = {
			size = 46,
		},
		split = {
			bag5 = true,
			player = true,
		},
		transparent = true,
		vendorGrays = {
			enable = true,
		},
	},
	chat = {
		copyChatLines = true,
		emotionIcons = false,
		fadeChatToggles = false,
		panelColor = {
			b = 0.0235294,
			g = 0.0431373,
			r = 0.0705882,
		},
		showHistory = {
			EMOTE = false,
			SAY = false,
			YELL = false,
		},
		tabSelectedTextColor = {
			b = 0,
			g = 0.415686,
		},
		tabSelectorColor = {
			b = 0,
			g = 0.415686,
		},
		timeStampFormat = "%H:%M:%S ",
		timeStampLocalTime = true,
	},
	cooldown = {
		actionbar = {
			thresholdText = {
				colors = {
					seconds = {
						b = 0.101961,
						g = 0.54902,
					},
				},
			},
		},
		global = {
			thresholdText = {
				colors = {
					seconds = {
						b = 0.101961,
						g = 0.54902,
					},
				},
			},
		},
		unitframe = {
			threshold = 4,
		},
	},
	databars = {
		azerite = {
			enable = false,
			textFormat = "CURMAX",
			width = 547,
		},
		colors = {
			quest = {
				a = 0,
				g = 0,
			},
		},
		experience = {
			showQuestXP = false,
		},
		honor = {
			showBubbles = true,
			textFormat = "CURMAX",
			width = 546,
		},
		reputation = {
			height = 235,
			orientation = "VERTICAL",
			width = 10,
		},
		threat = {
			enable = false,
			width = 262,
		},
	},
	datatexts = {
		font = "Expressway",
		fontOutline = "OUTLINE",
		noCombatClick = true,
		noCombatHover = true,
		panels = {
			MinimapPanel = {
				panelTransparency = true,
			},
		},
	},
	general = {
		altPowerBar = {
			statusBar = "WorldState Score",
		},
		autoRepair = "PLAYER",
		bordercolor = {
			b = 0.133333,
			g = 0.207843,
			r = 0.290196,
		},
		bottomPanel = false,
		decimalLength = 2,
		fonts = {
			objective = {
				enable = true,
			},
			pvpsubzone = {
				enable = true,
			},
			pvpzone = {
				enable = true,
			},
			talkingtext = {
				enable = true,
			},
			talkingtitle = {
				enable = true,
			},
			worldsubzone = {
				enable = true,
			},
			worldzone = {
				enable = true,
				size = 40,
			},
		},
		minimap = {
			icons = {
				classHall = {
					scale = 0.6,
					xOffset = -13,
					yOffset = -58,
				},
				mail = {
					texture = "Mail0",
					xOffset = 0,
					yOffset = 0,
				},
			},
			locationText = "HIDE",
		},
		stickyFrames = false,
		talkingHeadFrameScale = 1,
		totems = {
			growthDirection = "HORIZONTAL",
			size = 30,
			spacing = 1,
		},
		valuecolor = {
			b = 0.101961,
			g = 0.54902,
		},
	},
	movers = {
		AddonCompartmentMover = "TOPRIGHT,UIParent,TOPRIGHT,-4,-247",
		AltPowerBarMover = "BOTTOM,ElvUIParent,BOTTOM,0,340",
		ArenaHeaderMover = "TOPRIGHT,UIParent,TOPRIGHT,-49,-301",
		BossHeaderMover = "TOPRIGHT,UIParent,TOPRIGHT,-49,-300",
		ClassBarMover = "BOTTOM,ElvUIParent,BOTTOM,0,494",
		DurabilityFrameMover = "TOPRIGHT,ElvUIParent,TOPRIGHT,-204,-246",
		ElvNP_PlayerMover = "BOTTOM,ElvUIParent,BOTTOM,0,503",
		ElvUF_AssistMover = "TOPLEFT,ElvUIParent,TOPLEFT,526,-238",
		ElvUF_FocusCastbarMover = "BOTTOM,ElvUIParent,BOTTOM,0,438",
		ElvUF_PlayerAuraMover = "BOTTOM,ElvUIParent,BOTTOM,-216,540",
		ElvUF_RaidpetMover = "TOPLEFT,ElvUIParent,BOTTOMLEFT,4,737",
		ElvUF_TankMover = "TOPLEFT,ElvUIParent,TOPLEFT,518,-316",
		ElvUF_TargetAuraMover = "BOTTOM,ElvUIParent,BOTTOM,216,540",
		ElvUIBagMover = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,0,257",
		ElvUIBankMover = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,0,257",
		GMMover = "TOPLEFT,ElvUIParent,TOPLEFT,270,-8",
		KnuUI_ButtonsMover = "TOPRIGHT,ElvUIParent,TOPRIGHT,-8,-226",
		LevelUpBossBannerMover = "TOP,ElvUIParent,TOP,0,-270",
		MirrorTimer1Mover = "TOP,ElvUIParent,TOP,0,-289",
		ObjectiveFrameMover = "TOPRIGHT,ElvUIParent,TOPRIGHT,-28,-266",
		PlayerPowerBarMover = "BOTTOM,ElvUIParent,BOTTOM,-301,431",
		RaidMarkerBarAnchor = "BOTTOM,ElvUIParent,BOTTOM,0,361",
		RaidUtility_Mover = "TOP,ElvUIParent,TOP,-400,1",
		ReputationBarMover = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-553,23",
		SocialMenuMover = "TOPLEFT,ElvUIParent,TOPLEFT,4,-187",
		TalkingHeadFrameMover = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,284",
		ThreatBarMover = "BOTTOM,ElvUIParent,BOTTOM,0,258",
		TotemBarMover = "BOTTOM,ElvUIParent,BOTTOM,0,267",
		TotemTrackerMover = "BOTTOM,UIParent,BOTTOM,-197,368",
		UIErrorsFrameMover = "TOP,ElvUIParent,TOP,0,-212",
		VehicleLeaveButton = "BOTTOM,ElvUIParent,BOTTOM,148,334",
		VehicleSeatMover = "TOPRIGHT,ElvUIParent,TOPRIGHT,-340,-246",
	},
	nameplates = {
		clampToScreen = true,
		statusbar = "Polished Wood",
		units = {
			ENEMY_NPC = {
				buffs = {
					yOffset = 35,
				},
				eliteIcon = {
					enable = true,
					position = "LEFT",
					xOffset = 10,
					yOffset = 16,
				},
				health = {
					text = {
						font = "Expressway",
					},
				},
				name = {
					font = "Expressway",
					format = "[name:long]",
				},
				power = {
					enable = true,
					height = 6,
					text = {
						enable = true,
						fontSize = 12,
						format = "",
						position = "BOTTOMLEFT",
						yOffset = 10,
					},
					yOffset = -5,
				},
				questIcon = {
					yOffset = 20,
				},
			},
			ENEMY_PLAYER = {
				buffs = {
					maxDuration = 0,
					priority = "Blacklist,RaidBuffsElvUI,Dispellable,blockNoDuration,PlayerBuffs,TurtleBuffs,CastByUnit",
					yOffset = 35,
				},
				debuffs = {
					priority = "Blacklist,Personal,CCDebuffs",
				},
				health = {
					text = {
						font = "Expressway",
					},
				},
				level = {
					format = "[difficultycolor][level][shortclassification]",
				},
				name = {
					font = "Expressway",
					format = "[name]",
				},
				power = {
					enable = true,
					height = 6,
					text = {
						enable = true,
						fontSize = 12,
						format = "",
						position = "BOTTOMLEFT",
						yOffset = 10,
					},
					yOffset = -5,
				},
				title = {
					format = "[npctitle]",
				},
			},
			FRIENDLY_NPC = {
				debuffs = {
					size = 22,
				},
				health = {
					height = 5,
					text = {
						font = "Expressway",
						fontSize = 12,
					},
				},
				name = {
					font = "Expressway",
					fontSize = 10,
				},
				power = {
					height = 6,
					yOffset = -5,
				},
			},
			FRIENDLY_PLAYER = {
				debuffs = {
					size = 22,
				},
				health = {
					height = 5,
					text = {
						font = "Expressway",
						fontSize = 12,
					},
				},
				name = {
					font = "Expressway",
					fontSize = 10,
				},
				power = {
					height = 6,
					yOffset = -5,
				},
			},
		},
		visibility = {
			enemy = {
				pets = true,
				totems = true,
			},
		},
	},
	tooltip = {
		font = "Expressway",
		headerFont = "Expressway",
		headerFontSize = 14,
		healthBar = {
			font = "Expressway",
		},
		itemCount = {
			bags = false,
		},
		mythicDataEnable = false,
		showMount = false,
	},
	unitframe = {
		colors = {
			auraBarBuff = {
				b = 0.152941,
				g = 0.74902,
				r = 0.235294,
			},
			borderColor = {
				b = 0.133333,
				g = 0.207843,
				r = 0.290196,
			},
			castColor = {
				b = 0.101961,
				g = 0.54902,
			},
			frameGlow = {
				mainGlow = {
					class = true,
				},
			},
			healPrediction = {
				absorbs = {
					a = 0.61,
					b = 0.592157,
					r = 0.956863,
				},
				overabsorbs = {
					a = 0.61074,
					b = 1,
				},
				overhealabsorbs = {
					a = 0.61,
				},
			},
			health = {
				b = 0.301961,
				g = 0.690196,
			},
			transparentAurabars = true,
		},
		units = {
			arena = {
				health = {
					position = "BOTTOMRIGHT",
					text_format = "  [healthcolor][health:current:shortvalue]",
					xOffset = -2,
				},
				height = 40,
				name = {
					position = "TOPRIGHT",
					text_format = "[faction:icon][classcolor][name:medium]",
				},
				power = {
					attachTextTo = "Power",
					text_format = "[powercolor][curpp]",
				},
				width = 180,
			},
			assist = {
				enable = false,
			},
			boss = {
				buffs = {
					maxDuration = 300,
					priority = "Blacklist,TurtleBuffs,PlayerBuffs,Dispellable",
					sizeOverride = 27,
					yOffset = 16,
				},
				castbar = {
					width = 256,
				},
				debuffs = {
					desaturate = false,
					maxDuration = 300,
					priority = "Blacklist,blockNoDuration,Personal,CCDebuffs,Whitelist",
					sizeOverride = 27,
					yOffset = -16,
				},
				healPrediction = {
					enable = true,
				},
				health = {
					position = "BOTTOMRIGHT",
					text_format = "  [healthcolor][health:current:shortvalue]",
					xOffset = -2,
				},
				height = 40,
				infoPanel = {
					height = 17,
				},
				name = {
					position = "TOPRIGHT",
				},
				power = {
					attachTextTo = "Power",
					text_format = "[powercolor][curpp]",
				},
				width = 180,
			},
			party = {
				classbar = {
					enable = false,
				},
				rdebuffs = {
					size = 22,
					xOffset = -49,
					yOffset = 6,
				},
			},
			raid1 = {
				health = {
					position = "TOP",
					text_format = "[perhp]",
					xOffset = 14,
				},
				name = {
					position = "BOTTOMRIGHT",
					text_format = "[classcolor][name:veryshort]",
					xOffset = 2,
				},
				power = {
					height = 5,
				},
				raidicon = {
					attachTo = "RIGHT",
					size = 12,
				},
				rdebuffs = {
					size = 22,
					xOffset = -24,
					yOffset = 5,
				},
				resurrectIcon = {
					attachTo = "BOTTOMRIGHT",
				},
				roleIcon = {
					attachTo = "InfoPanel",
					position = "TOPLEFT",
					size = 14,
					xOffset = 0,
					yOffset = 4,
				},
			},
			tank = {
				enable = false,
			},
		},
	},
}
