require 'cinch'
require 'time'
require 'yaml'

class Fight
  include Cinch::Plugin
  prefix "@"
  
  MAX_EXPERIENCE_PER_WIN = 10
  MAX_EXPERIENCE_PER_TIE = 5

  LEVEL_FACTOR = 100
  
  TIME_BETWEEN_MAX_FIGHTS = 15 #in seconds
  MAX_FIGHTS = 2

  TIME_BETWEEN_QUESTS = 120 #in seconds
  QUEST_LENGTH = 60 #in seconds

  EQUIPMENT = YAML.load_file('plugins/fight/equipment.yml')

  WEAPONS = EQUIPMENT['weapons']
  ARMOR = EQUIPMENT['armor']


  
  #timer 120, method: :Give_AP
  #def Give_AP
  #  @bot.database.set("user:Dustin:AP", @bot.database.get("user:Dustin:AP").to_i + 1)
  #end
  
  match /^@fight (\S+) ?(.+)?/, method: :fight, :use_prefix => false
  
  def fight(m, command, param)
    case command
	when 'info'
      info m, param
	when 'create'
      create m
	when 'save'
      save m
	when 'help'
	  help m
	when 'quest'
	  quest m
	else
	  attack m, command
	end
  end
  
  
  def get_exp(param)
	@bot.database.get("user:#{param}:exp")
  end
  
  def reset_exp(param)
    	@bot.database.set("user:#{param}:exp", 0)
  end
	
  def save_exp(param,exp)
    	@bot.database.set("user:#{param}:exp", get_exp(param).to_i + exp.to_i)
  end
  
  def get_level(param)
	@bot.database.get("user:#{param}:level")
  end
  
  def save_level(param, level)
   	@bot.database.set("user:#{param}:level", level)
  end
  
  def get_weapon(param)
	@bot.database.get("user:#{param}:weapon")
  end
  
  def save_weapon(param, weapon)
    	@bot.database.set("user:#{param}:weapon", weapon)
  end
  
  def get_armor(param)
	@bot.database.get("user:#{param}:armor")
  end
  
  def save_armor(param, armor)
        @bot.database.set("user:#{param}:armor", armor)
  end
  
  def get_date(param)
	@bot.database.get("user:#{param}:time")
  end
  
  def save_date(param, time)
	@bot.database.set("user:#{param}:time", time)
  end
  
  def get_quest_date(param)
	@bot.database.get("user:#{param}:questtime")
  end
  
  def save_quest_date(param, time)
	@bot.database.set("user:#{param}:questtime", time)
  end
  
  def get_quests(param)
	@bot.database.get("user:#{param}:quests")
  end
  
  def save_quests(param, quests)
	@bot.database.set("user:#{param}:quests", quests)
  end
  
  def get_fights(param)
	@bot.database.get("user:#{param}:fights")
  end
  
  def save_fights(param, fights)
	@bot.database.set("user:#{param}:fights", fights)
  end
  
  def info (m, param)
	if param.nil?
		if get_level(m.user.nick).to_i >= 1
			info_weapon = WEAPONS[get_level(m.user.nick).to_i][get_weapon(m.user.nick).to_i]
			info_armor = ARMOR[get_level(m.user.nick).to_i][get_armor(m.user.nick).to_i]
			@bot.msg(m.user.nick,"-> 02#{m.user.nick}: Level [07#{get_level(m.user.nick)}] EXP: [03#{get_exp(m.user.nick)}/03#{get_level(m.user.nick).to_i*LEVEL_FACTOR}] Weapon: [06#{info_weapon['name']} | DMG: 131- #{info_weapon['damage']} | ELE: 14#{info_weapon['element']}] Armor: [06#{info_armor['name']} | ARM: 050-#{info_armor['armor']} | ELE: 14#{info_armor['element']}] AP: [#{@bot.database.get('user:Dustin:AP')}]")
		else
			@bot.msg(m.user.nick,"04-> You have not created a character.")
		end
	else
		if get_level(param).to_i >= 1
			info_weapon = WEAPONS[get_level(param).to_i][get_weapon(param).to_i]
			info_armor = ARMOR[get_level(param).to_i][get_armor(param).to_i]
			@bot.msg(m.user.nick,"-> 04#{param}: Level [07#{get_level(param)}] EXP: [03#{get_exp(param)}/03#{get_level(param).to_i*LEVEL_FACTOR}] Weapon: [06#{info_weapon['name']} | DMG: 131-#{info_weapon['damage']} | ELE: 14#{info_weapon['element']}] Armor: [06#{info_armor['name']} | ARM: 050-#{info_armor['armor']} | ELE: 14#{info_armor['element']}]")
		else
			@bot.msg(m.user.nick,"04-> #{param} has not created a character.")
		end
	end
  end
  
  
  
  def calculate_date(param)
	now = Time.now     # Current time
	past = Time.parse(get_date(param))
	
	if now - past > TIME_BETWEEN_MAX_FIGHTS
	  save_fights(param, 0)
	  save_date(param, Time.now)
	end
	
  end
  
  def calculate_quest_date(param)
	now = Time.now     # Current time
	past = Time.parse(get_quest_date(param))
	
	if now - past > TIME_BETWEEN_QUESTS
	  save_quests(param, 0)
	  save_quest_date(param, Time.now)
	end
	
  end
  
  def calculate_quest_time_left(param)
	now = Time.now     # Current time
	past = Time.parse(get_quest_date(param))
	
	return TIME_BETWEEN_QUESTS - (now - past)
  end
  
  def calculate_time_left(param)
	now = Time.now     # Current time
	past = Time.parse(get_date(param))
	
	return TIME_BETWEEN_MAX_FIGHTS - (now - past)
  end
  
  def calculate_level(param)
	current_level = get_level(param).to_i
	required_exp_new_level = current_level * LEVEL_FACTOR
	if get_exp(param).to_i >= required_exp_new_level
		new_level = current_level + 1
		save_level(param, new_level)
		reset_exp(param)
		randweapon = rand(5)
		randarmor = rand(5)
		save_weapon(param, randweapon)
		save_armor(param, randarmor)
		new_weapon = WEAPONS[new_level][randweapon]
		new_armor = ARMOR[new_level][randarmor]
		m.reply "-> 02#{param} reaches level 07#{get_level(param)}! Equips a new [06#{new_weapon['name']} | DMG: 131-#{new_weapon['damage']} | ELE: 14#{new_weapon['element']}] and [06#{new_armor['name']} | ARM: 050-#{new_armor['armor']} | ELE: 14#{new_armor['element']}]"
	end
  end
  
  def help(m)
	@bot.msg(m.user.nick,"-> Command List:-> 07@fight create (Creates a new character at level 1), 07@fight Username, 07@fight info Username (Displays Level,Exp,Weapon)")
	@bot.msg(m.user.nick,"-> Game Info:-> Fighting other people and winning results in gaining EXP, every (#{LEVEL_FACTOR} * Level) EXP gives you new level. Each new level you recieve a new weapon and armor piece of your current level. Weapons do damage from 1-WeaponDamage. Armor protects 0-ArmorAmount. To win a fight you have to do more damage then you take in a fight. Bonus EXP is awarded for defeating an opponent higher level then you.")
  end
  
  def create(m)
	randweapon = rand(5)
	randarmor = rand(5)
	save_weapon(m.user.nick, randweapon)
	save_armor(m.user.nick, randarmor)
	@bot.database.set("user:#{m.user.nick}:exp", 0)
	@bot.database.set("user:#{m.user.nick}:level", 1)
	@bot.database.set("user:#{m.user.nick}:time", Time.now)
	@bot.database.set("user:#{m.user.nick}:questtime", Time.now)
	@bot.database.set("user:#{m.user.nick}:quests", 0)
	@bot.database.set("user:#{m.user.nick}:fights", 0)
	starterweapon = WEAPONS[1][randweapon]
	starterarmor = ARMOR[1][randarmor]
	m.reply "-> New character created for 02#{m.user.nick}. Starting with [06#{starterweapon['name']} | DMG: 131-#{starterweapon['damage']} | ELE: 14#{starterweapon['element']} ] and [06#{starterarmor['name']} | ARM: 050-#{starterarmor['armor']} | ELE: 14#{starterarmor['element']}]"
  end
  
  def attack(m, param)
	if get_level(param).to_i >= 1
		defender_has_account = true
	else
		defender_has_account = false
	end
	
	if get_level(m.user.nick).to_i >= 1
		attacker_has_account = true
	else
		attacker_has_account = false
	end
	
	calculate_date(m.user.nick)
	
	if m.user.nick != param
		if get_fights(m.user.nick).to_i < MAX_FIGHTS		
			
			if attacker_has_account == true and defender_has_account == true
				save_fights(m.user.nick, get_fights(m.user.nick).to_i + 1)
				
				attacker_level = get_level(m.user.nick).to_i
				defender_level = get_level(param).to_i
				
				attacker_weapon = WEAPONS[attacker_level][get_weapon(m.user.nick).to_i]
				defender_weapon = WEAPONS[defender_level][get_weapon(param).to_i]
				
				attacker_armor = ARMOR[attacker_level][get_armor(m.user.nick).to_i]
				defender_armor = ARMOR[defender_level][get_armor(param).to_i]
				
				attacker_damage = rand(attacker_weapon['damage']) + 1
				defender_damage = rand(defender_weapon['damage']) + 1
				
				attacker_armor = rand(attacker_armor['armor'])
				defender_armor = rand(defender_armor['armor'])
				
				attacker_damage_done = attacker_damage - defender_armor
				defender_damage_done = defender_damage - attacker_armor

                                if m.user.nick == 'Mopman'
                                  attacker_damage_done = 9001
                                end
				
				if attacker_damage_done < 0
					attacker_damage_done = 0
				end
				
				if defender_damage_done < 0
					defender_damage_done = 0
				end
				
				
				m.reply "-> 02#{m.user.nick} [07#{get_level(m.user.nick)}] attacks 04#{param} with their 06#{attacker_weapon['name']} [DMG:02#{attacker_damage}-04#{defender_armor}:ARM] = 02#{attacker_damage_done} Damage Inflicted"
				m.reply "-> 04#{param} [07#{get_level(param)}] counters 02#{m.user.nick} with their 06#{defender_weapon['name']} [DMG:04#{defender_damage}-02#{attacker_armor}:ARM] = 04#{defender_damage_done} Damage Inflicted"
				
				if attacker_damage_done > defender_damage_done
					base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
					if get_level(param).to_i > get_level(m.user.nick).to_i
						bonus_exp = (base_exp * (get_level(param).to_i - get_level(m.user.nick).to_i))
					else
						bonus_exp = 0
					end
					earned_exp = base_exp + bonus_exp
					m.reply "-> 02#{m.user.nick}[07#{get_level(m.user.nick)}][03#{get_exp(m.user.nick)}/03#{get_level(m.user.nick).to_i*LEVEL_FACTOR}] beats 04#{param} [07#{get_level(param)}][03#{get_exp(param)}/03#{get_level(param).to_i*LEVEL_FACTOR}] and gains 03#{base_exp}+03#{bonus_exp}=03#{earned_exp} EXP."
					save_exp(m.user.nick, earned_exp)
					calculate_level(m.user.nick)
					
				end
				
				if attacker_damage_done < defender_damage_done
					base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
					if get_level(m.user.nick).to_i > get_level(param).to_i
						bonus_exp = (base_exp * (get_level(m.user.nick).to_i - get_level(param).to_i))
					else
						bonus_exp = 0
					end
					earned_exp = base_exp + bonus_exp
					m.reply "-> 04#{param}[07#{get_level(param)}][03#{get_exp(param)}/03#{get_level(param).to_i*LEVEL_FACTOR}] beats 02#{m.user.nick}[07#{get_level(m.user.nick)}][03#{get_exp(m.user.nick)}/03#{get_level(m.user.nick).to_i*LEVEL_FACTOR}] and gains 03#{base_exp}+03#{bonus_exp}=03#{earned_exp} EXP."
					save_exp(param, earned_exp)
					calculate_level(param)
				end
				
				if attacker_damage_done == defender_damage_done
					earned_exp = rand(MAX_EXPERIENCE_PER_TIE)+1
					m.reply "-> 02#{m.user.nick}[07#{get_level(m.user.nick)}][03#{get_exp(m.user.nick)}/03#{get_level(m.user.nick).to_i*LEVEL_FACTOR}] ties 04#{param}[07#{get_level(param)}][03#{get_exp(param)}/03#{get_level(param).to_i*LEVEL_FACTOR}] and both gain 03#{earned_exp} EXP."
					save_exp(m.user.nick, earned_exp)
					save_exp(param, earned_exp)
					calculate_level(m.user.nick)
					calculate_level(param)
					
				end
			else
				if attacker_has_account == true and defender_has_account == false
					@bot.msg(m.user.nick,"04->  #{param} has not setup a character.")
				end
				if attacker_has_account == false and defender_has_account == true
					@bot.msg(m.user.nick,"04-> You have not setup a character.")
				end
				if attacker_has_account == false and defender_has_account == false
					@bot.msg(m.user.nick,"04-> You and #{param} have not setup characters.")
				end
			end
		else
			@bot.msg(m.user.nick,"04-> You can only fight 02#{MAX_FIGHTS}04 times in 02#{TIME_BETWEEN_MAX_FIGHTS}04 seconds, you've got 03#{calculate_time_left(m.user.nick).to_i}04 seconds left.")
		end
	else
		@bot.msg(m.user.nick,"04-> You're trying to attack yourself? 5 EXP MINUS!")
		save_exp(m.user.nick,-5)
	end
  end
end
