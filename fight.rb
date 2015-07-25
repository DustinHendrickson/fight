require 'cinch'
require 'time'
require 'yaml'

# Code by Dustin Hendrickson
# dustin.hendrickson@gmail.com

class Fight
include Cinch::Plugin
prefix '@'


# Configuration Variables=======
MAX_EXPERIENCE_PER_WIN = 10
MAX_EXPERIENCE_PER_TIE = 5

ELEMENT_BONUS = 3

LEVEL_FACTOR = 100

MINIMUM_DAMAGE = 1
#===============================

# Color Definitions
RED = '04'
BLUE = '12'
GREEN = '03'
BLACK = '01'
BROWN = '05'
PURPLE = '06'
YELLOW = '08'
TEAL = '11'
ORANGE = '07'
PINK = '13'
GREY = '14'
BOLD = ''
CF = '' #CLEAR FORMATTING

# Read the config file in for items and set arrays.
EQUIPMENT = YAML.load_file('plugins/fight/equipment.yml')

WEAPONS = EQUIPMENT['weapons']
ARMOR = EQUIPMENT['armor']

# Timer Method to run the Attack Function every interval.
timer 120, method: :attack

# Regex to grab the command trigger string.
match /^@fight (\S+) ?(.+)?/, method: :fight, :use_prefix => false

# Run the functions based on passed in command.
def fight(m, command, param)
	case command
		when 'info'
		  info m, param
		when 'create'
		  create m
		when 'help'
		  help m
	end
end

# Database Getters and Setters
def dbGet(username, key)
	@bot.database.get("user:#{username}:#{key}")
end

def dbSet(username, key, value)
	@bot.database.set("user:#{username}:#{key}", value)
end

# This function takes a username and displays that user's account details.
def info (m, param)
	if param.nil?
		if dbGet(m.user.nick, 'level').to_i >= 1
			info_weapon = WEAPONS[dbGet(m.user.nick, 'level').to_i][dbGet(m.user.nick, 'weapon').to_i]
			info_armor = ARMOR[dbGet(m.user.nick, 'level').to_i][dbGet(m.user.nick, 'armor').to_i]
			@bot.msg(m.user.nick,"#{BOLD}-> #{BLUE}#{m.user.nick}#{CF}: Level [#{ORANGE}#{dbGet(m.user.nick, 'level')}#{CF}] EXP: [#{GREEN}#{dbGet(m.user.nick, 'exp')}#{CF}/#{GREEN}#{dbGet(m.user.nick, 'level').to_i*LEVEL_FACTOR}#{CF}] Weapon: [#{PURPLE}#{info_weapon['name']}#{CF} | DMG: #{PINK}1#{CF}-#{PINK}#{info_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(info_weapon['element'], info_weapon['element'])}] Armor: [#{PURPLE}#{info_armor['name']}#{CF} | ARM: #{BROWN}0#{CF}-#{BROWN}#{info_armor['armor']}#{CF} | ELE: #{wrapInElementColor(info_armor['element'], info_armor['element'])}]")
		else
			@bot.msg(m.user.nick, "#{RED}#{BOLD}-> You have not created a character.")
		end
	else
		if dbGet(param, 'level').to_i >= 1
			info_weapon = WEAPONS[dbGet(param, 'level').to_i][dbGet(param, 'weapon').to_i]
			info_armor = ARMOR[dbGet(param, 'level').to_i][dbGet(param, 'armor').to_i]
			@bot.msg(m.user.nick,"#{BOLD}-> #{RED}#{param}#{CF}: Level [#{ORANGE}#{dbGet(param, 'level')}#{CF}] EXP: [#{GREEN}#{dbGet(param, 'exp')}#{CF}/#{GREEN}#{dbGet(param, 'level').to_i*LEVEL_FACTOR}#{CF}] Weapon: [#{PURPLE}#{info_weapon['name']}#{CF} | DMG: #{PINK}1#{CF}-#{PINK}#{info_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(info_weapon['element'], info_weapon['element'])}] Armor: [#{PURPLE}#{info_armor['name']}#{CF} | ARM: #{BROWN}0#{CF}-#{BROWN}#{info_armor['armor']}#{CF} | ELE: #{wrapInElementColor(info_armor['element'], info_armor['element'])}]")
		else
			@bot.msg(m.user.nick,"#{RED}#{BOLD}-> #{param} has not created a character.")
		end
	end
end

# Wraps whole string in color based on supplied element.
def wrapInElementColor(stringToWrap, element)
	case element
		when "Fire"
			return "#{RED}#{stringToWrap}#{CF}"
		when "Water"
			return "#{TEAL}#{stringToWrap}#{CF}"
		when "Life"
			return "#{GREEN}#{stringToWrap}#{CF}"
		else
			return "#{GREY}#{stringToWrap}#{CF}"
		end
end

# Returns element bonus vs strength check.
def getElementBonus(elementAttacker, elementDefender)
	case [elementAttacker, elementDefender]
		when ['Fire', 'Life']
			return "+#{wrapInElementColor(ELEMENT_BONUS, elementAttacker)}"
		when ['Water', 'Fire']
			return "+#{wrapInElementColor(ELEMENT_BONUS, elementAttacker)}"
		when ['Life', 'Water']
			return "+#{wrapInElementColor(ELEMENT_BONUS, elementAttacker)}"
		when ['Life', 'Fire']
			return "-#{wrapInElementColor(ELEMENT_BONUS, elementAttacker)}"
		when ['Fire', 'Water']
			return "-#{wrapInElementColor(ELEMENT_BONUS, elementAttacker)}"
		when ['Water', 'Life']
			return "-#{wrapInElementColor(ELEMENT_BONUS, elementAttacker)}"
	else
		return ""
	end
end

# Returns short element code with color.
def getElementTag(element)
	case element
		when "Fire"
			return "#{wrapInElementColor('F', element)}"
		when "Water"
			return "#{wrapInElementColor('W', element)}"
		when "Life"
			return "#{wrapInElementColor('L', element)}"
		else
			return "#{wrapInElementColor('N', element)}"
		end
end

# If a number is negative, 0 it out.
def fixNegativeNumbers(number)
	if number < 0
		return 0
	else
		return number
	end
end

# Checks to see if user has leveled up.
def calculate_level(param)
	current_level = dbGet(param, 'level').to_i
	required_exp_new_level = current_level * LEVEL_FACTOR
	if dbGet(param, 'exp').to_i >= required_exp_new_level
		new_level = current_level + 1
		dbSet(param, 'level', new_level)
		dbSet(param, 'exp', 0)
		randweapon = rand(5)
		randarmor = rand(5)
		dbSet(param, 'weapon', randweapon)
		dbSet(param, 'armor', randarmor)
		new_weapon = WEAPONS[new_level][randweapon]
		new_armor = ARMOR[new_level][randarmor]

		chan = @bot.channels.sample
		channel = Channel(chan)

		channel.msg '----------------------------------------------------'
		channel.msg "#{BOLD}-> #{BLUE}#{param}#{CF} reaches level #{ORANGE}#{dbGet(param, 'level')}#{CF}! Equips a new [#{PURPLE}#{new_weapon['name']}#{CF} | DMG: #{PINK}1#{CF}-#{PINK}#{new_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(new_weapon['element'], new_weapon['element'])}] and [#{PURPLE}#{new_armor['name']}#{CF} | ARM: #{BROWN}0#{CF}-#{BROWN}#{new_armor['armor']}#{CF} | ELE: #{wrapInElementColor(new_armor['element'], new_armor['element'])}]"
	end
end

# Displays help documentation.
def help(m)
	@bot.msg(m.user.nick,"#{BOLD}-> Command List:#{BOLD}-> #{ORANGE}@fight create#{CF} (Creates a new character at level 1), #{ORANGE}@fight info Username#{CF} (Displays Level, Exp, Equipment, if no username is given, will display your own stats.) #{ORANGE}@fight ai#{CF} (Pairs you against an AI fight.)")
	@bot.msg(m.user.nick," ")
	@bot.msg(m.user.nick,"#{BOLD}-> Game Info:#{BOLD} Fight! is an idle RPG game where you will have little input in the process. The bot will periodically pick 2 random registered users in the room and make them fight eachother, winning results in gaining EXP, every (#{LEVEL_FACTOR} * Level) EXP gives you new level. Each new level you will recieve a random new weapon and armor piece of your level. Weapons do damage from 1-WeaponDamage. Armor protects 0-ArmorAmount. To win a fight you have to do more damage then you take in a single exchange of swings. Bonus EXP is awarded for defeating an opponent higher level then you.")
	@bot.msg(m.user.nick," ")
	@bot.msg(m.user.nick,"#{BOLD}-> Game Info cont..:#{BOLD}  Elements play a big factor here, your weapon can randomly have either the #{RED}Fire#{CF}, #{GREEN}Life#{CF} or #{TEAL}Water#{CF} elements. When you attack someone it will check your Weapon Element vs their Armor Element, if your weapon element beats their armor element, you will recieve +3 damage. If it is weak against the other, you will get -3 damage.")
	@bot.msg(m.user.nick," ")
	@bot.msg(m.user.nick,"#{BOLD}-> Element Chart:#{BOLD} #{BOLD}#{RED}Fire#{CF}->#{GREEN}Life#{CF} | #{GREEN}Life#{CF}->#{TEAL}Water#{CF} | #{TEAL}Water#{CF}->#{RED}Fire#{CF}#{BOLD}")
end

# Create a new character.
def create(m)
	randweapon = rand(5)
	randarmor = rand(5)
	dbSet(m.user.nick, 'weapon', randweapon)
	dbSet(m.user.nick, 'armor', randarmor)
	dbSet(m.user.nick, 'exp', 0)
	dbSet(m.user.nick, 'level', 1)
	starterweapon = WEAPONS[1][randweapon]
	starterarmor = ARMOR[1][randarmor]
	m.reply "#{BOLD}-> New character created for #{BLUE}#{m.user.nick}#{CF}. Starting with [#{PURPLE}#{starterweapon['name']}#{CF} | DMG: #{PINK}1-#{starterweapon['damage']}#{CF} | ELE: #{wrapInElementColor(starterweapon['element'], starterweapon['element'])} ] and [#{PURPLE}#{starterarmor['name']}#{CF} | ARM: #{BROWN}0-#{starterarmor['armor']}#{CF} | ELE: #{wrapInElementColor(starterarmor['element'], starterarmor['element'])}]"
end

# Create a new AI character.
def createAI(level)
	randweapon = rand(5)
	randarmor = rand(5)
	dbSet('AI', 'weapon', randweapon)
	dbSet('AI', 'armor', randarmor)
	dbSet('AI', 'exp', 0)
	dbSet('AI', 'level', level)
end

def fightai(m)
	attack(:a => m, :b => 'AI')
end

# Main function of the plugin, performs combat.
# Can pass registered Username (option[:a])
# 'AI' (option[:b]) to initiate an AI fight.
def attack( options={} )
	chan = @bot.channels.sample
	channel = Channel(chan)

	# Setup default options if ai fight was passed to the function.
	if options[:b] == 'AI'
		usernameA = options[:a].user.nick
		usernameB = 'AI'
		createAI(dbGet(usernameA, 'level').to_i)
	else
		# Loop till we find a valid user
		usernameA = ''
		i = 0
		while usernameA == 'Fight|Bot' || usernameA == ''
			usernameA = chan.users.keys.sample.nick
			if dbGet(usernameA, 'level').to_i <= 0
				usernameA = ''
			end
			i +=1
			if i >= 50
				usernameA = ''
				break
			end
		end

		# Loop till we find a valid user to fight against userA.
		usernameB = ''
		i = 0
		while usernameB == 'Fight|Bot' || usernameB == '' || usernameA == usernameB || dbGet(usernameB, 'level').to_i <= 0
			usernameB = chan.users.keys.sample.nick
			if dbGet(usernameB, 'level').to_i <= 0
				usernameB = ''
			end
			i +=1
			if i >= 50
				usernameB = ''
				# We can't find anyone to fight against, but we have someone
				# who wants to fight, so we'll pair them with an AI.
				if usernameA != ''
					usernameB = 'AI'
					createAI(dbGet(usernameA, 'level').to_i)
				end
				break
			end
		end
	end

	# We don't want to do anything if any of the users didnt get set.
	if usernameA != '' && usernameB != ''
			attacker_level = dbGet(usernameA, 'level').to_i
			defender_level = dbGet(usernameB, 'level').to_i

			attacker_weapon = WEAPONS[attacker_level][dbGet(usernameA, 'weapon').to_i]
			defender_weapon = WEAPONS[defender_level][dbGet(usernameB, 'weapon').to_i]

			attacker_armorworn = ARMOR[attacker_level][dbGet(usernameA, 'armor').to_i]
			defender_armorworn = ARMOR[defender_level][dbGet(usernameB, 'armor').to_i]

			attacker_damage = rand(attacker_weapon['damage']) + MINIMUM_DAMAGE
			defender_damage = rand(defender_weapon['damage']) + MINIMUM_DAMAGE

			attacker_armor = rand(attacker_armorworn['armor'])
			defender_armor = rand(defender_armorworn['armor'])

			#============================================================================
			# Element Definitions =======================================================
			#============================================================================
			attacker_weapon_element_bonus = getElementBonus(attacker_weapon['element'], defender_armorworn['element'])
			defender_weapon_element_bonus = getElementBonus(defender_weapon['element'], attacker_armorworn['element'])

			attacker_base_damage = attacker_damage
			defender_base_damage = defender_damage

			# Calculate bonus element damage
			attacker_bonus_modifier = attacker_weapon_element_bonus[0]
			case attacker_bonus_modifier
				when "+"
					attacker_damage += ELEMENT_BONUS
				when "-"
					attacker_damage -= ELEMENT_BONUS
			end

			defender_bonus_modifier = defender_weapon_element_bonus[0]
			case defender_bonus_modifier
				when "+"
					defender_damage += ELEMENT_BONUS
				when "-"
					defender_damage -= ELEMENT_BONUS
			end
			#============================================================================

			# Here we make sure there's no negative numbers.
			attacker_base_damage = fixNegativeNumbers(attacker_base_damage)
			defender_base_damage = fixNegativeNumbers(defender_base_damage)
			attacker_damage = fixNegativeNumbers(attacker_damage)
			defender_damage = fixNegativeNumbers(defender_damage)

			# Calculate Damage
			attacker_damage_done = attacker_damage - defender_armor
			defender_damage_done = defender_damage - attacker_armor

			# Make sure we can do math on the numbers.
			attacker_damage_done = fixNegativeNumbers(attacker_damage_done)
			defender_damage_done = fixNegativeNumbers(defender_damage_done)

			channel.msg '----------------------------------------------------'
			channel.msg "-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}] attacks #{RED}#{usernameB}#{CF}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}] with #{PURPLE}#{attacker_weapon['name']}#{CF} #{getElementTag(attacker_weapon['element'])}[DMG:#{BLUE}#{attacker_base_damage}#{CF}#{attacker_weapon_element_bonus}#{CF}-#{RED}#{defender_armor}#{CF}:ARM]#{getElementTag(defender_armorworn['element'])} = #{BLUE}#{attacker_damage_done}#{CF} Damage Inflicted"
			channel.msg "-> #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}] counters #{BLUE}#{usernameA}#{CF}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}] with #{PURPLE}#{defender_weapon['name']}#{CF} #{getElementTag(defender_weapon['element'])}[DMG:#{RED}#{defender_base_damage}#{CF}#{defender_weapon_element_bonus}#{CF}-#{BLUE}#{attacker_armor}#{CF}:ARM]#{getElementTag(attacker_armorworn['element'])} = #{RED}#{defender_damage_done}#{CF} Damage Inflicted"
			channel.msg '----------------------------------------------------'

			# Here we start to calculate the battle results
			# Check to see if the attacker did more damage than the defender and sets EXP.
			if attacker_damage_done > defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if dbGet(usernameB, 'level').to_i > dbGet(usernameA, 'level').to_i
					bonus_exp = (base_exp * (dbGet(usernameB, 'level').to_i - dbGet(usernameA, 'level').to_i))
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}][#{GREEN}#{dbGet(usernameA, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameA, 'level').to_i*LEVEL_FACTOR}#{CF}] beats #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}][#{GREEN}#{dbGet(usernameB, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameB, 'level').to_i*LEVEL_FACTOR}#{CF}] and gains #{GREEN}#{base_exp}#{CF}+#{GREEN}#{bonus_exp}#{CF}=#{GREEN}#{earned_exp}#{CF} EXP."
				dbSet(usernameA, 'exp', dbGet(usernameA, 'exp').to_i + earned_exp.to_i)
				calculate_level(usernameA)
			end

			# Defender Wins
			if attacker_damage_done < defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if dbGet(usernameA, 'level').to_i > dbGet(usernameB, 'level').to_i
					bonus_exp = (base_exp * (dbGet(usernameA, 'level').to_i - dbGet(usernameB, 'level').to_i))
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "#{BOLD}-> #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}][#{GREEN}#{dbGet(usernameB, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameB, 'level').to_i*LEVEL_FACTOR}#{CF}] beats #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}][#{GREEN}#{dbGet(usernameA, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameA, 'level').to_i*LEVEL_FACTOR}#{CF}] and gains #{GREEN}#{base_exp}#{CF}+#{GREEN}#{bonus_exp}#{CF}=#{GREEN}#{earned_exp}#{CF} EXP."
				dbSet(usernameB, 'exp', dbGet(usernameB, 'exp').to_i + earned_exp.to_i)
				calculate_level(usernameB)
			end

			# Tie
			if attacker_damage_done == defender_damage_done
				earned_exp = rand(MAX_EXPERIENCE_PER_TIE)+1
				channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}][#{GREEN}#{dbGet(usernameA, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameA, 'level').to_i*LEVEL_FACTOR}#{CF}] ties #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}][#{GREEN}#{dbGet(usernameB, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameB, 'level').to_i*LEVEL_FACTOR}#{CF}] and both gain #{GREEN}#{earned_exp}#{CF} EXP."
				dbSet(usernameA, 'exp', dbGet(usernameA, 'exp').to_i + earned_exp.to_i)
				dbSet(usernameB, 'exp', dbGet(usernameB, 'exp').to_i + earned_exp.to_i)
				calculate_level(usernameA)
				calculate_level(usernameB)
			end
	end # End Null Users Check.
end # End Of Attack

end # End Class
