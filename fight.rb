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

random = 0

# Timer Method to run the Attack Function every interval.
timer 120, method: :attack

# Regex to grab the command trigger string.
match /^@fight (\S+) ?(.+)? (.+)/, method: :fight, :use_prefix => false

# Run the functions based on passed in command.
def fight(m, command, param, param2)
	case command
		when 'info'
			info m, param
		when 'create'
			create m
		when 'help'
			help m
		when 'quest'
			startquest m
		when 'duel'
			duel m, param, param2
	end
end

def duel(m, param, param2)
	attackerUsername = m.user.nick
	defenderUsername = param
	expBet = param2.to_i

	if attackerUsername != defenderUsername
		if dbGet(attackerUsername, 'exp').to_i >= expBet.to_i && dbGet(defenderUsername, 'level').to_i > 0
			if expBet.to_i >= 10
				@bot.msg(attackerUsername, "#{BOLD}-> #{GREEN} You started a duel and bet #{expBet.to_i} exp.#{CF}")
				attack(:a => m, :b => defenderUsername, :duel => 'true', :expBet => expBet)
			else 
				@bot.msg(attackerUsername, "#{BOLD}-> #{RED} You must bet at least 10 exp.#{CF}")
			end
		else
			@bot.msg(attackerUsername, "#{BOLD}-> #{RED} You do not have enough experience to bet that much. Or the person you're trying to duel does not have an account.#{CF}")
		end
	else 
		@bot.msg(attackerUsername, "#{BOLD}-> #{RED} You can't fight yourself....#{CF}")
	end

end

def startquest(m)
	if dbGet(m.user.nick, 'exp').to_i >= 15
		dbSet(m.user.nick, 'exp', dbGet(m.user.nick, 'exp').to_i - 15)
		@bot.msg(m.user.nick,"#{BOLD}-> #{GREEN} You have started a quest manually, costing you 15 exp.#{CF}")
		quest(:username => m.user.nick)
	else
		@bot.msg(m.user.nick,"#{BOLD}-> #{RED} You do not have enough EXP to start a quest, it costs 15.#{CF}")
	end
end


def quest(options={})
	chan = @bot.channels.sample
	channel = Channel(chan)
	random = 0

	#Select a random user from the channel
	if options[:username] != ''
		username = options[:username]
	else
		username = ''
	end

	if dbGet(username, 'level').to_i > 0
		channel.msg("#{BOLD}#{GREEN}#{username} has embarked on a quest.#{CF}")

		random = rand(100)
		# User will earn bonus EXP
		if random <= 65 && random > 20
			earned_exp = rand(25)+10
			channel.msg "#{BOLD}-> #{BLUE}#{username}#{CF} has completed their quest successfully and earned #{earned_exp} bonus exp!"
			dbSet(username, 'exp', dbGet(username, 'exp').to_i + earned_exp.to_i)
			dbSet(username, 'quests_completed', dbGet(username, 'quests_completed').to_i + 1)
			calculate_level(username)
		end
		# User will earn new items.
		if random <= 20
			randweapon = rand(5)
			randarmor = rand(5)
			dbSet(username, 'weapon', randweapon)
			dbSet(username, 'armor', randarmor)
			dbSet(username, 'quests_completed', dbGet(username, 'quests_completed').to_i + 1)
			new_weapon = WEAPONS[dbGet(username, 'level').to_i][randweapon]
			new_armor = ARMOR[dbGet(username, 'level').to_i][randarmor]
			channel.msg "#{BOLD}-> #{BLUE}#{username}#{CF} has completed their quest successfully, during the quest they lost their weapons but found new ones #{new_weapon} and #{new_armor}."
		end
		# Quest was failed.
		if random > 65
			dbSet(username, 'quests_failed', dbGet(username, 'quests_failed').to_i + 1)
			channel.msg "#{BOLD}-> #{RED}#{username}#{CF} has completely and utterly failed their quest."
		end
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
			wins = dbGet(m.user.nick, "wins").to_i
			loses = dbGet(m.user.nick, "loses").to_i
			ties = dbGet(m.user.nick, "ties").to_i
			killing_spree = dbGet(m.user.nick, "killing_spree").to_i
			losing_spree = dbGet(m.user.nick, "losing_spree").to_i
			quests_completed = dbGet(m.user.nick, "quests_completed").to_i
			quests_failed = dbGet(m.user.nick, "quests_failed").to_i
			win_totals = (wins + loses + ties)
			quest_totals = (quests_completed + quests_failed)
			if win_totals > 0
				win_percent = (wins / win_totals).to_f * 100
			else
				win_percent = 0
			end
			if quest_totals > 0
				quest_percent = (quests_completed / quest_totals).to_f * 100
			else
				quest_percent = 0
			end
			@bot.msg(m.user.nick,"#{BOLD}-> #{BLUE}#{m.user.nick}#{CF}: Level [#{ORANGE}#{dbGet(m.user.nick, 'level')}#{CF}] EXP: [#{GREEN}#{dbGet(m.user.nick, 'exp')}#{CF}/#{GREEN}#{dbGet(m.user.nick, 'level').to_i*LEVEL_FACTOR}#{CF}] Weapon: [#{PURPLE}#{info_weapon['name']}#{CF} | DMG: #{PINK}1#{CF}-#{PINK}#{info_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(info_weapon['element'], info_weapon['element'])}] Armor: [#{PURPLE}#{info_armor['name']}#{CF} | ARM: #{BROWN}0#{CF}-#{BROWN}#{info_armor['armor']}#{CF} | ELE: #{wrapInElementColor(info_armor['element'], info_armor['element'])}]")
			@bot.msg(m.user.nick,"#{BOLD} [Wins: #{wins}] [Loses: #{loses}] [Ties: #{ties}] [Killing Spree: #{killing_spree}] [Losing Spree: #{losing_spree}] [Quests Completed: #{quests_completed}] [Quests Failed: #{quests_failed}] [Win Percent: #{win_percent}%] [Quest Success Percent: #{quest_percent}%]#{CF}")
		else
			@bot.msg(m.user.nick, "#{RED}#{BOLD}-> You have not created a character.")
		end
	else
		if dbGet(param, 'level').to_i >= 1
			info_weapon = WEAPONS[dbGet(param, 'level').to_i][dbGet(param, 'weapon').to_i]
			info_armor = ARMOR[dbGet(param, 'level').to_i][dbGet(param, 'armor').to_i]
			wins = dbGet(param, "wins").to_i
			loses = dbGet(param, "loses").to_i
			ties = dbGet(param, "ties").to_i
			killing_spree = dbGet(param, "killing_spree").to_i
			losing_spree = dbGet(param, "losing_spree").to_i
			quests_completed = dbGet(param, "quests_completed").to_i
			quests_failed = dbGet(param, "quests_failed").to_i
			win_totals = (wins + loses + ties)
			quest_totals = (quests_completed + quests_failed)
			if win_totals > 0
				win_percent = (wins / win_totals).to_f * 100
			else
				win_percent = 0
			end
			if quest_totals > 0
				quest_percent = (quests_completed / quest_totals).to_f * 100
			else
				quest_percent = 0
			end
			@bot.msg(m.user.nick,"#{BOLD}-> #{RED}#{param}#{CF}: Level [#{ORANGE}#{dbGet(param, 'level')}#{CF}] EXP: [#{GREEN}#{dbGet(param, 'exp')}#{CF}/#{GREEN}#{dbGet(param, 'level').to_i*LEVEL_FACTOR}#{CF}] Weapon: [#{PURPLE}#{info_weapon['name']}#{CF} | DMG: #{PINK}1#{CF}-#{PINK}#{info_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(info_weapon['element'], info_weapon['element'])}] Armor: [#{PURPLE}#{info_armor['name']}#{CF} | ARM: #{BROWN}0#{CF}-#{BROWN}#{info_armor['armor']}#{CF} | ELE: #{wrapInElementColor(info_armor['element'], info_armor['element'])}]")
			@bot.msg(m.user.nick,"#{BOLD} [Wins: #{wins}] [Loses: #{loses}] [Ties: #{ties}] [Killing Spree: #{killing_spree}] [Losing Spree: #{losing_spree}] [Quests Completed: #{quests_completed}] [Quests Failed: #{quests_failed}] [Win Percent: #{win_percent}%] [Quest Success Percent: #{quest_percent}%]#{CF}")
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
	@bot.msg(m.user.nick,"#{BOLD}-> Command List: Message the bot these commands #{BOLD}-> #{ORANGE}@fight create#{CF} (Creates a new character at level 1), #{ORANGE}@fight info Username#{CF} (Displays Level, Exp, Equipment, if no username is given, will display your own stats.) #{ORANGE}@fight quest#{CF} this costs 15 exp, chance to get bonus exp or new weapons of your level.")
	@bot.msg(m.user.nick," ")
	@bot.msg(m.user.nick,"#{BOLD}-> Game Info:#{BOLD} Fight! is an idle RPG game where you will have little input in the process. The bot will periodically pick 2 random registered users in the room and make them fight each other, winning results in gaining EXP, every (#{LEVEL_FACTOR} * Level) EXP gives you new level. Each new level you will receive a random new weapon and armor piece of your level. Weapons do damage from 1-WeaponDamage. Armor protects 0-ArmorAmount. To win a fight you have to do more damage then you take in a single exchange of swings. You can crit against a higher level than you, adding LEVEL_DIFFERENCE extra damage if successful. Bonus EXP is awarded for defeating an opponent higher level then you.")
	@bot.msg(m.user.nick," ")
	@bot.msg(m.user.nick,"#{BOLD}-> Game Info cont..:#{BOLD}  Elements play a big factor here, your weapon can randomly have either the #{RED}Fire#{CF}, #{GREEN}Life#{CF} or #{TEAL}Water#{CF} elements. When you attack someone it will check your Weapon Element vs their Armor Element, if your weapon element beats their armor element, you will receive +3 damage. If it is weak against the other, you will get -3 damage.")
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
		#If there's a manual fight, let's check and set the username
		if options[:duel] == 'true'
			usernameA = options[:a].user.nick
			usernameB = options[:b]
		end
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
			attacker_is_higher_level = false
			defender_is_higher_level = false
			defender_crit = ''
			attacker_crit = ''
			attacker_losing_spree = dbGet(usernameA, 'losing_spree').to_i
			defender_losing_spree = dbGet(usernameB, 'losing_spree').to_i

			#Let's get the level difference
			if attacker_level > defender_level
				level_difference = attacker_level - defender_level
				attacker_is_higher_level = true
			end

			if defender_level > attacker_level
				level_difference = defender_level - attacker_level
				defender_is_higher_level = true
			end

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

			# Check for crits for lower levels.
			if attacker_is_higher_level == true
				random = rand(5)
				if random <= 2
					defender_damage = defender_damage + level_difference
					defender_crit = ' CRIT! + ' + level_difference + ' '
				end
			end

			if defender_is_higher_level == true
				random = rand(5)
				if random <= 2
					attacker_damage = attacker_damage + level_difference
					attacker_crit = ' CRIT! + ' + level_difference + ' '
				end
			end


			# Calculate Damage
			attacker_damage_done = attacker_damage - defender_armor
			defender_damage_done = defender_damage - attacker_armor

			# Make sure we can do math on the numbers.
			attacker_damage_done = fixNegativeNumbers(attacker_damage_done)
			defender_damage_done = fixNegativeNumbers(defender_damage_done)

			channel.msg '----------------------------------------------------'
			channel.msg "-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}] attacks #{RED}#{usernameB}#{CF}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}] with #{PURPLE}#{attacker_weapon['name']}#{CF} #{getElementTag(attacker_weapon['element'])}#{attacker_crit}[DMG:#{BLUE}#{attacker_base_damage}#{CF}#{attacker_weapon_element_bonus}#{CF}-#{RED}#{defender_armor}#{CF}:ARM]#{getElementTag(defender_armorworn['element'])} = #{BLUE}#{attacker_damage_done}#{CF} Damage Inflicted"
			channel.msg "-> #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}] counters #{BLUE}#{usernameA}#{CF}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}] with #{PURPLE}#{defender_weapon['name']}#{CF} #{getElementTag(defender_weapon['element'])}#{defender_crit}[DMG:#{RED}#{defender_base_damage}#{CF}#{defender_weapon_element_bonus}#{CF}-#{BLUE}#{attacker_armor}#{CF}:ARM]#{getElementTag(attacker_armorworn['element'])} = #{RED}#{defender_damage_done}#{CF} Damage Inflicted"
			channel.msg '----------------------------------------------------'

			# Here we start to calculate the battle results
			# Check to see if the attacker did more damage than the defender and sets EXP.
			if attacker_damage_done > defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if defender_level > attacker_level
					bonus_exp = (base_exp * (defender_level - attacker_level)) + attacker_losing_spree
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}][#{GREEN}#{dbGet(usernameA, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameA, 'level').to_i*LEVEL_FACTOR}#{CF}] beats #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}][#{GREEN}#{dbGet(usernameB, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameB, 'level').to_i*LEVEL_FACTOR}#{CF}] and gains #{GREEN}#{base_exp}#{CF}+#{GREEN}#{bonus_exp}#{CF}=#{GREEN}#{earned_exp}#{CF} EXP."
				dbSet(usernameA, 'exp', dbGet(usernameA, 'exp').to_i + earned_exp.to_i)
				dbSet(usernameA, 'wins', dbGet(usernameA, 'wins').to_i + 1)
				dbSet(usernameB, 'loses', dbGet(usernameB, 'loses').to_i + 1)
				dbSet(usernameA, 'killing_spree', dbGet(usernameA, 'killing_spree').to_i + 1)
				dbSet(usernameB, 'killing_spree', 0)
				dbSet(usernameB, 'losing_spree', dbGet(usernameB, 'losing_spree').to_i + 1)
				dbSet(usernameA, 'losing_spree', 0)
				if options[:duel] == 'true'
					dbSet(usernameA, 'exp', dbGet(usernameA, 'exp').to_i + options[:expBet])
					channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF} has dueled #{RED}#{usernameB}#{CF} and won an extra #{options[:expBet]} EXP!"
				end
				calculate_level(usernameA)
				if dbGet(usernameA, 'killing_spree').to_i == 5
					channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF} redeems their killing spree bonus for a free quest!"
					quest(:username => usernameA)
				end
			end

			# Defender Wins
			if attacker_damage_done < defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if attacker_level > defender_level
					bonus_exp = (base_exp * (attacker_level - defender_level)) + defender_losing_spree
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "#{BOLD}-> #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}][#{GREEN}#{dbGet(usernameB, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameB, 'level').to_i*LEVEL_FACTOR}#{CF}] beats #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}][#{GREEN}#{dbGet(usernameA, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameA, 'level').to_i*LEVEL_FACTOR}#{CF}] and gains #{GREEN}#{base_exp}#{CF}+#{GREEN}#{bonus_exp}#{CF}=#{GREEN}#{earned_exp}#{CF} EXP."
				dbSet(usernameB, 'exp', dbGet(usernameB, 'exp').to_i + earned_exp.to_i)
				dbSet(usernameB, 'wins', dbGet(usernameB, 'wins').to_i + 1)
				dbSet(usernameA, 'loses', dbGet(usernameA, 'loses').to_i + 1)
				dbSet(usernameB, 'killing_spree', dbGet(usernameB, 'killing_spree').to_i + 1)
				dbSet(usernameA, 'killing_spree', 0)
				dbSet(usernameA, 'losing_spree', dbGet(usernameA, 'losing_spree').to_i + 1)
				dbSet(usernameB, 'losing_spree', 0)
				if options[:duel] == 'true'
					dbSet(usernameA, 'exp', dbGet(usernameA, 'exp').to_i - options[:expBet])
					dbSet(usernameB, 'exp', dbGet(usernameB, 'exp').to_i + options[:expBet])
					channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF} has dueled #{RED}#{usernameB}#{CF} and LOST #{options[:expBet]} EXP!"
				end
				calculate_level(usernameB)
				if dbGet(usernameB, 'killing_spree').to_i == 5
					channel.msg "#{BOLD}-> #{BLUE}#{usernameB}#{CF} redeems their killing spree bonus for a free quest!"
					quest(:username => usernameB)
				end
			end

			# Tie
			if attacker_damage_done == defender_damage_done
				earned_exp = rand(MAX_EXPERIENCE_PER_TIE)+1
				channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{dbGet(usernameA, 'level')}#{CF}][#{GREEN}#{dbGet(usernameA, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameA, 'level').to_i*LEVEL_FACTOR}#{CF}] ties #{RED}#{usernameB}#{CF}[#{ORANGE}#{dbGet(usernameB, 'level')}#{CF}][#{GREEN}#{dbGet(usernameB, 'exp')}#{CF}/#{GREEN}#{dbGet(usernameB, 'level').to_i*LEVEL_FACTOR}#{CF}] and both gain #{GREEN}#{earned_exp}#{CF} EXP."
				dbSet(usernameA, 'exp', dbGet(usernameA, 'exp').to_i + earned_exp.to_i)
				dbSet(usernameB, 'exp', dbGet(usernameB, 'exp').to_i + earned_exp.to_i)
				dbSet(usernameA, 'ties', dbGet(usernameA, 'ties').to_i + 1)
				dbSet(usernameB, 'ties', dbGet(usernameB, 'ties').to_i + 1)
				dbSet(usernameA, 'killing_spree', 0)
				dbSet(usernameA, 'losing_spree', 0)
				dbSet(usernameB, 'killing_spree', 0)
				dbSet(usernameB, 'losing_spree', 0)
				calculate_level(usernameA)
				calculate_level(usernameB)
			end
	end # End Null Users Check.
end # End Of Attack

end # End Class
