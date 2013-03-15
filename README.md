# Fight Plugin

An IRC bot plugin written for [CadBot_Cinch](https://github.com/cadwallion/cadbot_cinch) IRC Bot. 

## Installation

Before you can install fight, you must have a working instance of Cadbot running.  Please see the [README](https://github.com/cadwallion/cadbot_cinch)
for instructions on how to install and configure Cadbot.

To install Fight, first clone this repository to the `plugin` directory in your bot's `plugins` directory:

```
cd BOT_DIRECTORY/plugins && git clone git://github.com/dustinhendrickson/fight.git 
```

If you have customized where your plugins directory is located in your bot, be sure to update the clone 
location accordingly. Restart your bot and the plugin will be automatically loaded.

## Usage

Fight adds two commands to your bot: `@fight create` and `@fight info username`.

`fight create` - Creates a new character at level 1.  Use this to be able to start fighting with other users.
`fight info username` - Displays information about `username`, including Level, Exp, and Equipment.

## Game Info

Fighting other people and winning results in gaining EXP, every `(100 * Level)` EXP gives you new level. Every 
levelup you recieve a new random weapon and piece of armor. Weapons do damage from 1-WeaponDamage. Armor 
protects `0-ArmorAmount`. To win a fight you have to do more damage then you take in a fight. Bonus EXP 
is awarded for defeating an opponent higher level then you. This is an IDLE RPG, which means at 
intervals the bot will pick two people with accounts in the channel and make them fight.
