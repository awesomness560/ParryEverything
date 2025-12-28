extends Resource
class_name MessageBank

var chatUsers : Array[String] = [
	# The Sweats
	"xX_DemonSlayer_Xx", "FrameData_Addict", "NoHit_Runner", "Speedrun_Steve", 
	"TryHard_77", "Sweaty_Palms", "GitGud_Scrub", "Meta_Slave", "Tech_Chaser",
	
	# The Memers
	"Pog_Champ_2025", "MemeLord_Omega", "Dorito_Dust", "Gamer_Bathwater", 
	"Shrek_Fan_Account", "Despacito_Player", "Keyboard_Warrior", "Lag_Excuse_Official",
	
	# The Regulars
	"Coffee_Enjoyer", "NightOwl", "Casual_Dad", "JustHereToWatch", "Lurker_001",
	"Sub_Since_Day_1", "Mod_Wannabe", "StreamSniper_LUL", "Pizza_Delivery_Guy",
	
	# The Bots/Suspicious
	"Twitch_Prime_Loot", "Ad_Bot_9000", "User_8471029", "Russian_Hacker?", 
	"Not_A_Bot_Trust_Me", "FBI_Surveillance_Van", "System_Admin", "Unity_Error_Log",
	
	# The Lore/Thematic
	"Physics_Professor", "Issac_Newton_Ghost", "Gravity_Police", "Grim_Reaper_Official",
	"Sword_Saint", "Parry_God_Disciple", "Reality_Anchor"
]

# RANK 0: The Warmup / Skeptics / Mundane
# Use when style is low or combo just started.
var rank0Messages : Array[String] = [
	# Bored/Casual
	"Stream starting?", "hi chat", "First", "Any mods on?", "What game is this?",
	"brb getting water", "mic check?", "is this a rerun?", "dead chat",
	"resident sleeper", "audio desync?", "skip intro pls", "controller disconnected?",
	"just joined what did i miss", "looks easy", "my grandma could do that",
	
	# Critique
	"missed a spot", "sloppy inputs", "try parrying earlier", "lag?", 
	"dropped frames", "low bitrate", "focus up", "warmup routine",
	"stop mashing", "rng carried", "bad rng", "reset run",
	
	# Encouragement (Mild)
	"nice try", "almost", "close one", "shake it off", "keep going",
	"you got this", "focus", "lock in", "waking up?", "okay okay",
	"not bad", "decent start", "warming up the hands"
]

# RANK 1: The Build Up / Competence
# Use when the player hits a small streak.
var rank1Messages : Array[String] = [
	# Approval
	"There we go", "Getting cleaner", "Nice read", "Good reaction",
	"Solid", "Crispy inputs", "Okay I see you", "Respect",
	"Not bad kid", "Better than my teammates", "Smooth", "Clean",
	"Looking sharp", "Gamer posture engaged", "He's focusing",
	"No hit run?", "Momentum building", "Nice parry", "Good tech",
	
	# Observation
	"That was intentional", "Calculated", "Planned it", "Read like a book",
	"Download complete", "Pattern recognition", "Rhythm game?",
	"Flow state initiating", "Inputs looking good", "0 delay",
	"Monitor turned on", "Gaming chair activated", "Sweat mode on",
	
	# Hype (Low)
	"lets go", "pog?", "nice one", "caught that", "wp", "GG",
	"clutch potential", "breathing room", "clean execution"
]

# RANK 2: The Hype / The "Pop Off"
# Use for Perfect Parries or long combos.
var rank2Messages : Array[String] = [
	# Excitement
	"POGGERS", "LETS GOOOOO", "YOOOOOO", "SHEEEESH", "W STREAM",
	"HYPERS", "POGCHAMP", "CLIPPED", "CLIP THAT", "MOM GET THE CAMERA",
	"INSANE", "SICK", "NASTY", "FILTHY", "DISGUSTING (compliment)",
	
	# Praise
	"Built different", "Cracked", "Goated", "Actually good?", 
	"Check him PC", "Aimbot for swords", "Wallhacks?", "Scripted??",
	"Paid actor", "He don't miss", "Pixel perfect", "Frame perfect",
	"Hitbox porn", "Satisfying", "ASMR for my eyes",
	
	# Aggressive
	"SIT DOWN", "GET REKT", "ROLLED", "SMOKED", "DIFFED",
	"DELETED", "RETURN TO SENDER", "NO U", "ACCESS DENIED",
	"GET OUT OF HERE", "NOT IN MY HOUSE", "EZ CLAP"
]

# RANK 3: The Absurd / Breaking Logic
# Use when parrying heavy attacks or huge groups.
var rank3Messages : Array[String] = [
	# Disbelief
	"WHAT???", "HOW????", "EXCUSE ME??", "HUH??", "WAIT WHAT",
	"NO WAY", "IMPOSSIBLE", "UNREAL", "I WAS THERE", "WITNESS",
	"MY EYES", "AM I DREAMING?", "GLITCH IN THE MATRIX",
	"BROKE THE GAME", "DEV PLS EXPLAIN", "ADMINS???",
	
	# Accusations
	"HACKS CONFIRMED", "VAC BAN", "TAS BOT", "NOT HUMAN",
	"ALIEN REFLEXES", "FUTURE SIGHT", "HE CAN SEE TIME",
	"READING THE CODE", "INPUT READING", "LAG SWITCH??",
	
	# Screaming
	"OMGGGGGG", "WTF WTF WTF", "HOLY MOLY", "JESUS CHRIST",
	"GOD GAMER", "ACTUALLY GOD", "PROTOCOL OMEGA",
	"MAXIMUM OVERDRIVE", "LIMIT BREAK", "ULTRA INSTINCT",
	"HE IS HIM", "THE CHOSEN ONE", "MAIN CHARACTER"
]

# RANK 4: The Ascended / Cosmic Horror
# Use for "Parrying The Ground", "Parrying Death", or Max Style.
var rank4Messages : Array[String] = [
	# Reality Breaking
	"REALITY.EXE STOPPED WORKING", "PHYSICS NOT FOUND", "ERROR 404: LOGIC",
	"NEWTON IS CRYING", "LAWS OF PHYSICS: OPTIONAL", "GRAVITY DENIED",
	"ENTROPY REVERSED", "TIME PARADOX DETECTED", "UNIVERSAL CONSTANT DELETED",
	"MATH IS WRONG", "SCIENCE CANNOT EXPLAIN THIS", "1+1=3",
	
	# Worship
	"I KNEEL", "🛐🛐🛐", "ALL HAIL", "OUR GOD", "PREACH",
	"THE PROPHET", "ASCENDED", "BEYOND GODLIKE", "ENTITY DETECTED",
	"WORSHIP HIM", "SACRIFICE ME", "TAKE MY ENERGY", "SPIRIT BOMB READY",
	
	# System Errors (Glitches)
	"SYSTEM FAILURE", "CRITICAL ERROR", "BUFFER OVERFLOW",
	"01001000 01000101 01001100 01010000", "NULL REFERENCE EXCEPTION",
	"KILL_PROCESS: DEATH", "OVERRIDE_AUTHORITY: TRUE", "SUDO PARRY",
	
	# Pure Gibberish/Chaos
	"LITERALLY UNKILLABLE", "IMAGINE DYING LOL", "DEATH IS A CHOICE",
	"KEYBOARD SMASH", "FDJKSL;A FJKDSL;A", "AAAAAAAAAAAAAAAAA",
	"MY BRAIN IS MELTING", "SEND HELP", "MOM I'M SCARED",
	"HE JUST PARRIED THE END CREDITS", "HE PARRIED THE CONCEPT OF LOSING"
]

# CONTEXT SPECIFIC: Checks against the parry tag
var contextMessages : Dictionary = {
	# If parrying floor/fall damage
	"Ground": [
		"Did he just parry the FLOOR?", "Earth.exe stopped working",
		"Screw Gravity", "Newton rolling in his grave",
		"Ground collision: OFF", "Walking is for losers",
		"He hates the floor", "The floor is lava? No, the floor is PARRIED."
	],
	# If parrying a fatal hit/death trigger
	"Death": [
		"NOT TODAY SATAN", "Refused to die", "Grim Reaper got parried",
		"Immortality glitch", "Plot Armor: 100%", "Denied death",
		"Too angry to die", "Life subscription renewed"
	],
	# If parrying fire/lava
	"Fire": [
		"Spicy!!", "Toasty!", "Hot hot hot", "Thermodynamics? No.",
		"Fireproof hands", "Cooler than cool", "Ouch?"
	],
	# If parrying a massive boss nuke
	"Nuke": [
		"Return to sender", "Uno Reverse Card", "No u",
		"Parried a hydrogen bomb???", "That's a war crime",
		"Eat that", "Parry > Explosion"
	]
}
