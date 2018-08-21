Playing sounds with nPose is quite fun though there are many options available for making them happen..

Variables:  
Volume - 0 to 1  
Play time (float) in seconds.  
Looping of sound can be turned ON or OFF.  If OFF the sounds play only once, if ON the list of sounds play over and over.  
Arb. number for turning sounds on = -2345  
Arb number for turning sounds off = -2344  

To setup nPose to play sounds make a notecard to hold all of the sound keys to play.  Each key should be on a single line.  Following the key in each line add a comma and enter the Play time.  Now all that is needed is a way to call that notecard.  
Example  
NC name: Snd1  
content:  
```
900bdb8a-a208-1c9b-c08e-c67016bf3069,1.0
f5fe4e73-715b-933f-ab06-a160f25fbc9c,1.0
```

Step 1:  
Add the nPose Sound Plugin .012 script to the nPose build.  The script can reside in any linked prim as long as the notecard containing the list of sound keys also resides in the same prim.

Step 2:  
Add the sound notecard to the same prim as the script.  More than one sound notecard can be used for playing other sounds.  nPose is not limited to one sound notecard.

Step 3:  
To set up a chair that will play a sound or list of sounds when someone sits simply add a SATMSG line to an existing pose set notecard.  For this example the DEFAULT notecard is used.  It is a single AV pose set so only one seat position is available.  The contents of this DEFAULT notecard are the following:

```
ANIM|sit crossed|<-0.01573, 0.07928, 0.22998>|<0.00000, 0.00000, -90.00000>|
SATMSG|-2345|Snd1~1.0~looping=OFF
```

The SATMSG line uses the Arb. number for turning sounds ON followed by a set of 3 variables needed to run the sound.  
Snd1 is the name of our notecard containing the list of sound keys and play times to use.  
1.0 is the volume to play the sound.  This one is set to highest volume.  
looping will tell the sound plugin script to loop or not loop the list of sounds.  The script knows to only play the list of sounds once and not loop back to the beginning.

Some options:  
The notecard also could a NOTSATMSG  which would turn OFF the sound when the AV stands up.  This Arb. number takes no variables.  This might be handy if the looping variable is ON.  
`NOTSATMSG|-2344`

A BTN notecard could be addes as well to turn off the sounds using LINKMSG.  
`LINKMSG|-2344`

Step 4:  
Add the DEFAULT notecard to the nPose build.

Finished.... now when someone sits on this nPose build, the sounds in the notecard will play once.
______________________________________________________________________________________


Suppose we want a menu button to play this sound list whenever we want to hear it.  We will need to use a BTN notecard with a LINKMSG line to accomplish this.the BTN notecard would contain the following line:
LINKMSG|-2345|Snd1~1.0~looping=OFF

Add this notecard to the build and the menu will have a button to select and play this sound whenever we want to hear it.





