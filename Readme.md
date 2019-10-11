# nPose Sound Plugin
The nPose Sound Plugin allows you to play sounds within your nPose object. This ranges from a simple sound effect up to a complete juke box.

## Usage
Add the following lines to the top of your `.init` NC (if you don't have an `.init` NC then create one):
```
PLUGINCOMMAND|SOUND_STOP|-2344
PLUGINCOMMAND|SOUND|-2346
PLUGINCOMMAND|SOUND_NC|-2347
```
If you want to use a prop as a sound source add the following lines (instead of the above);
```
PLUGINCOMMAND|SOUND_STOP|-2344|1
PLUGINCOMMAND|SOUND|-2346|1
PLUGINCOMMAND|SOUND_NC|-2347|1
```
Place the nPose Sound Plugin script into the prim that should be the source of the sound. This could be any prim within the linkset of the nPose object or a prop. You can use multiple sound sources (place the nPose Sound Plugin in each). To be able to "address" a specific prim you can add a "identifier" to the prim description (see below).

## Prim description / Identifier
To "address" a prim inside a linkset we use the description field of the prim to give it an identifier. Please don't use plain numbers as identifier. If you want to give a prim more than one identifier then separate the identifiers by ~. You can also use one identifier for more than one prim.

## Commands
```
SOUND|target|name[, params][|name[, params]]...
SOUND_NC|target|name[, params][|name[, params]]...
SOUND_STOP|target
```
`target`: a comma separated list of identifiers (see Prim description above) or the wildcard `*`  
`name`: the name or uuid of a sound (SOUND) or of a sound-notecard (SOUND_NC). If you use a name, then the sound/sound-notecard have to be inside the same prim as the nPose Sound Plugin. (Special: The name "SILENCE" can be used with a SOUND command or inside a sound-notecard.)  
`params`: a comma separated list of key=value pairs

| key     | value type | range     | default value | description |
| ------- | ---------- | --------- | ------------- | ----------- |
| length  | float      | 0.0 - ∞   | 0.0           | length of the sound in seconds. If used with the SOUND_NC command, then this length will become the default value of all sounds inside the sound-notecard.
| volume  | float      | 0.0 - 1.0 | 1.0           | the volume of the sound. If used with the SOUND_NC command, then this volume will become the default value of all sounds inside the NC.
| trigger | integer    | 0\|1      | 0             | 0: the nPose Sound Plugin plays an attached sound (the sound moves with the prim), 1: the nPose Sound Plugin plays an unattached sound (the sound does not move with the prim)
| reps    | integer    | -1 - ∞    | 0             | -1: the sound is played forever, any non negative number: number of repetitions
| queue   | integer    | 0\|1      | 0             | 0: the sound is played immediately (a current sound will be stopped), 1: the sound is played after the current queued sounds.

## Sound-notecard
inside a sound notecard each sound is written in a new line with the syntax:  
`name[, params]`  
`name`: the name or uuid of a sound (Special: The name "SILENCE" can be used)  
`params`: the same as above. Please make sure that you provide at least the `length` param.

`META|key=value[|key=value]...` Metadata for the sound-nc. If the global option `soundMetaBroadcast` is set, these will be send by llMessageLinked(LINK_SET, SOUND_META_BROADCAST_CURRENT(-2348) or SOUND_META_BROADCAST_LAST(-2349), a JSON object with the key value pairs, user uuid);    
`DO|a nPose command` Example: Place `DO|DOCARD|yourCardName` at the end of the NC to do something when the sound ends.

## Global options
`soundMasterVolume`: default=0.9; all individual volumes are multiplied with this value. This can be used to allow the enduser to globaly change the volume (This will NOT work if you use the Sound Plugin inside a prop).  
`soundMetaBroadcast`: 0|1 default value 0, set to 1 if you want the script to broadcast SOUND_META_BROADCAST_CURRENT(-2348) and SOUND_META_BROADCAST_LAST(-2349) messages