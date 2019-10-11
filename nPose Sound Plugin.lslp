/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
	- If you distribute the nPose scripts, you must leave them full perms.
	- If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/

integer SOUND_STOP=-2344;
integer SOUND_NC_OLD=-2345;
integer SOUND=-2346;
integer SOUND_NC=-2347;
integer SOUND_META_BROADCAST_CURRENT=-2348;
integer SOUND_META_BROADCAST_LAST=-2349;
integer DO=220;
integer OPTIONS=-240;
integer MEMORY_USAGE=34334;


integer PLUGIN_COMMAND_REGISTER=310;

string PLUGIN_COMMAND_NAME_SOUND_STOP="SOUND_STOP";
string PLUGIN_COMMAND_NAME_SOUND_NC="SOUND_NC";
string PLUGIN_COMMAND_NAME_SOUND="SOUND";

string SOUND_SILENCE_NAME="SILENCE";
string SOUND_SILENCE_UUID="00000000-0000-0000-0000-000000000114";

string TYPE_SOUND="⟣";
string TYPE_NC="⟢";
string TYPE_DO="⟁";
string TYPE_META_BROADCAST_CURRENT="⟝";
string TYPE_META_BROADCAST_LAST="⟞";
string TYPE_META_BROADCAST_PLACEHOLDER="⟂";

integer SOUND_QUEUE_STRIDE=9;
list SoundQueue;
//8-strided list [
// 0: string type (NC or Sound)
// 1: string name or uuid,
// 2: float length
// 3: integer reps
// 4: integer queue
// 5: integer trigger
// 6: float volume
// 7: integer preload
// 8: user uuid
//]
list CurrentNotecardData;
//list [
// 0: string type (NC)
// 1: string name or uuid,
// 2: float length
// 3: integer reps
// 4: integer queue
// 5: integer trigger
// 6: float volume
// 7: integer preload
// 8: user uuid
// 9: integer currentLine
// 10: key request uuid
// 11: totalLength
//]
list CurrentNotecardMetaDataNames;
list CurrentNotecardMetaDataValues;

integer _TYPE=0;
integer _NAME=1;
integer _LENGTH=2;
integer _REPS=3;
integer _QUEUE=4;
integer _TRIGGER=5;
integer _VOLUME=6;
integer _PRELOAD=7;
integer _USER_UUID=8;
integer _CURRENT_LINE=9;
integer _REQUEST_UUID=10;
integer _TOTAL_LENGTH=11;

string TAG_TOTAL_LENGTH="_length";
string TAG_TOTAL_LENGTH_STRING="_length_string";
string TAG_ID="_id";
string TAG_PRIM_NAME="_prim_name";
string TAG_PRIM_DESC="_prim_desc";

integer Playing;

float OptionSoundVolume=0.9;
integer OptionSoundMetaBroadcast=FALSE;

integer StatMaxNumberOfQueueEntries;
integer StatSoundsRequested;
integer StatSoundNcsRequested;
integer StatSoundItemsPlayed;

debug(list message){
	llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

string convertOldCommandSyntax(string str) {
	list params=llParseString2List(str, ["~"], []);
	if(llGetListLength(params)==3) {
		return llList2CSV([
			llList2String(params, 0),
			"volume="+llList2String(params, 1),
			"reps="+(string)((integer)(llList2String(params, 2)=="looping=ON")*-1)
		]);
	}
	return str;
}

string convertOldNcSyntax(string str) {
	list params=llCSV2List(str);
	if(llSubStringIndex(llList2String(params, 1), "=")==-1) {
		params=llListReplaceList(params, ["length=" + llList2String(params, 1)], 1, 1);
	}
	return llList2CSV(params);
}

string timeStringFromSeconds(integer seconds) {
	string timeString;
	integer hours=seconds/3600;
	if(hours) {
		seconds=seconds-hours*3600;
		timeString+=llGetSubString("00"+(string)hours, -2, -1)+":";
	}
	integer minutes=seconds/60;
	if(minutes) {
		seconds=seconds-minutes*60;
	}
	if(timeString) {
		timeString+=llGetSubString("00"+(string)minutes, -2, -1)+":";
	}
	else {
		timeString+=(string)minutes+":";
	}
	timeString+=llGetSubString("00"+(string)seconds, -2, -1);
	return timeString;
}

integer isTarget(string targetNames) {
	if(targetNames=="" || targetNames=="*") {
		return TRUE;
	}

	string description=llList2String(llGetPrimitiveParams([PRIM_DESC]), 0);
	if(description=="(No Description)") {
		description="";
	}
	list myTargetNamesList=llParseString2List(description, ["~"], []);

	list targetNamesList=llParseString2List(targetNames, ["~"], []);
	integer index;
	integer length=llGetListLength(targetNamesList);
	for(index=0; index<length; index++) {
		if(~llListFindList(myTargetNamesList, [llList2String(targetNamesList, index)])) {
			return TRUE;
		}
	}
	return FALSE;
}

list getParams(string allParamsString, list defaultValues) {
	string paramType=llList2String(defaultValues, _TYPE);
	string paramName=llList2String(defaultValues, _NAME);
	float paramLength=llList2Float(defaultValues, _LENGTH);
	integer paramReps=llList2Integer(defaultValues, _REPS);
	integer paramQueue=llList2Integer(defaultValues, _QUEUE);
	integer paramTrigger=llList2Integer(defaultValues, _TRIGGER);
	float paramVolume=llList2Float(defaultValues, _VOLUME);
	integer paramPreload=llList2Integer(defaultValues, _PRELOAD);
	key paramUserUuid=llList2Key(defaultValues, _USER_UUID);
	
	list allParams=llCSV2List(allParamsString);
	
	//check for valid names
	paramName=llList2String(allParams, 0);
	if((key)paramName) {
		//it is a uuid
	}
	else {
		//its a string
		if(paramType==TYPE_SOUND) {
			if(llGetInventoryType(paramName)!=INVENTORY_SOUND) {
				if(paramName==SOUND_SILENCE_NAME) {
					paramName=SOUND_SILENCE_UUID;
				}
				else {
					return [];
				}
			}
		}
		else if(paramType==TYPE_NC) {
			if(llGetInventoryType(paramName)!=INVENTORY_NOTECARD) {
				return [];
			}
		}
	}
	
	integer index;
	integer length=llGetListLength(allParams);
	for(index=1; index<length; index++) {
		list optionsItems = llParseString2List(llList2String(allParams, index), ["="], []);
		string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
		string optionString = llList2String(optionsItems, 1);
		string optionSetting = llToLower(llStringTrim(optionString, STRING_TRIM));
		integer optionSettingFlag = optionSetting=="on" || (integer)optionSetting;
		
		if(optionItem=="length") {
			paramLength=(float)optionSetting;
		}
		else if(optionItem=="reps") {
			paramReps=(integer)optionSetting;
		}
		else if(optionItem=="queue") {
			paramQueue=optionSettingFlag;
		}
		else if(optionItem=="trigger") {
			paramTrigger=optionSettingFlag;
		}
		else if(optionItem=="volume") {
			paramVolume=(float)optionSetting;
		}
		else if(optionItem=="preload") {
			paramPreload=optionSettingFlag;
		}
	}
	return [paramType, paramName, paramLength, paramReps, paramQueue, paramTrigger, paramVolume, paramPreload, paramUserUuid];
}

execQueue() {
	if(llGetListLength(SoundQueue)>StatMaxNumberOfQueueEntries) {
		StatMaxNumberOfQueueEntries=llGetListLength(SoundQueue);
	}
	integer break;
	integer index;
	while(!break && index<llGetListLength(SoundQueue)) {
		string paramType=llList2String(SoundQueue, index+_TYPE);
		string paramNameOrUuid=llList2String(SoundQueue, index+_NAME);
		float paramLength=llList2Float(SoundQueue, index+_LENGTH);
		integer paramReps=llList2Integer(SoundQueue, index+_REPS);
		integer paramQueue=llList2Integer(SoundQueue, index+_QUEUE);
		integer paramTrigger=llList2Integer(SoundQueue, index+_TRIGGER);
		float paramVolume=llList2Float(SoundQueue, index+_VOLUME);
		integer paramPreload=llList2Integer(SoundQueue, index+_PRELOAD);
		key paramUserUuid=llList2Key(SoundQueue, index+_USER_UUID);
		if(paramType==TYPE_SOUND) {
			//preload first
			if(paramPreload) {
				llPreloadSound(paramNameOrUuid);
				paramPreload=0;
				SoundQueue=llListReplaceList(SoundQueue, [paramPreload], index+_PRELOAD, index+_PRELOAD);
			}
			if(!Playing) {
				//idle: start sound
				StatSoundItemsPlayed++;
				float effectiveVolume=OptionSoundVolume*paramVolume;
				//make the sound
				if(paramTrigger) {
					llTriggerSound(paramNameOrUuid, effectiveVolume);
				}
				else {
					if(paramReps<0) {
						llLoopSound(paramNameOrUuid, effectiveVolume);
					}
					else {
						llPlaySound(paramNameOrUuid, effectiveVolume);
					}
				}
				if(paramLength>0.0) {
					Playing=TRUE;
					if(paramReps>=0) {
						llSetTimerEvent(paramLength);
					}
				}
				//correct the queue
				paramReps--;
				if(paramReps>=0 && paramLength>0.0) {
					SoundQueue=llListReplaceList(SoundQueue, [paramReps], index+_REPS, index+_REPS);
					break=TRUE;
				}
				else {
					SoundQueue=llDeleteSubList(SoundQueue, index, index+SOUND_QUEUE_STRIDE-1);
					index-=SOUND_QUEUE_STRIDE;
				}
			}
			else {
				break=TRUE;
			}
		}
		else if(paramType==TYPE_NC){
			//Notecard found
			if(!llGetListLength(CurrentNotecardData)) {
				CurrentNotecardData=[paramType, paramNameOrUuid, paramLength, paramReps, paramQueue, paramTrigger, paramVolume, paramPreload, paramUserUuid, 0, NULL_KEY, 0.0];
				CurrentNotecardMetaDataNames=[TAG_ID, TAG_PRIM_NAME, TAG_PRIM_DESC]; 
				CurrentNotecardMetaDataValues=[paramNameOrUuid] + llGetPrimitiveParams([PRIM_NAME, PRIM_DESC]);
				if(OptionSoundMetaBroadcast) {
					SoundQueue=llListInsertList(SoundQueue, [TYPE_META_BROADCAST_PLACEHOLDER, paramNameOrUuid, 0.0, 0, 1, 0, 0.0, 0, paramUserUuid], index);
					index+=SOUND_QUEUE_STRIDE;
				}
				readNotecard();
			}
			break=TRUE;
		}
		else if(paramType==TYPE_META_BROADCAST_LAST) {
			if(!Playing) {
				SoundQueue=llDeleteSubList(SoundQueue, index, index+SOUND_QUEUE_STRIDE-1);
				index-=SOUND_QUEUE_STRIDE;
				llMessageLinked(LINK_SET, SOUND_META_BROADCAST_LAST, paramNameOrUuid, paramUserUuid);
			}
		}
		else if(paramType==TYPE_META_BROADCAST_CURRENT) {
				SoundQueue=llDeleteSubList(SoundQueue, index, index+SOUND_QUEUE_STRIDE-1);
				index-=SOUND_QUEUE_STRIDE;
				llMessageLinked(LINK_SET, SOUND_META_BROADCAST_CURRENT, paramNameOrUuid, paramUserUuid);
		}
		else if(paramType==TYPE_META_BROADCAST_PLACEHOLDER) {
		}
		else if(paramType==TYPE_DO) {
			if(!Playing) {
				SoundQueue=llDeleteSubList(SoundQueue, index, index+SOUND_QUEUE_STRIDE-1);
				index-=SOUND_QUEUE_STRIDE;
				llMessageLinked(LINK_SET, DO, paramNameOrUuid, paramUserUuid);
			}
		}
		index+=SOUND_QUEUE_STRIDE;
	}
}

clearQueue() {
	Playing=FALSE;
	llSetTimerEvent(0.0);
	while(llGetListLength(SoundQueue)) {
		string paramType=llList2String(SoundQueue, _TYPE);
		if(paramType==TYPE_META_BROADCAST_LAST) {
			string paramNameOrUuid=llList2String(SoundQueue, _NAME);
			key paramUserUuid=llList2Key(SoundQueue, _USER_UUID);
			llMessageLinked(LINK_SET, SOUND_META_BROADCAST_LAST, paramNameOrUuid, paramUserUuid);
		}
		SoundQueue=llDeleteSubList(SoundQueue, 0, SOUND_QUEUE_STRIDE-1);
	}
	CurrentNotecardData=[];
	CurrentNotecardMetaDataNames=[]; 
	CurrentNotecardMetaDataValues=[]; 
}

readNotecard() {
	if(llGetListLength(CurrentNotecardData)) {
		string name=llList2String(CurrentNotecardData, _NAME);
		integer line=llList2Integer(CurrentNotecardData, _CURRENT_LINE);
		key handle=llGetNotecardLine(name, line);
		CurrentNotecardData=llListReplaceList(CurrentNotecardData, [line+1, handle], _CURRENT_LINE, _CURRENT_LINE+1);
	}
}

default {
	state_entry() {
	}

	link_message(integer sender_num, integer num, string str, key id) {
		if(num==SOUND_NC_OLD) {
			str="*|" + convertOldCommandSyntax(str);
			num=SOUND_NC;
		}
		if(num==SOUND || num==SOUND_NC) {
			string paramType=TYPE_SOUND;
			if(num==SOUND_NC) {
				paramType=TYPE_NC;
			}

			integer flagExecQueue;
			list commands=llParseStringKeepNulls(str, ["|"], []);
			//the first part should be the target
			if(isTarget(llList2String(commands, 0))) { 
				integer length=llGetListLength(commands);
				integer index;
				for(index=1; index<length; index++) {
					list queueStride=getParams(llList2String(commands, index), [paramType, "", 0.0, 0, index>1, 0, 1.0, num==SOUND_NC, id]);
					if(queueStride) {
						StatSoundNcsRequested+=num==SOUND_NC;
						StatSoundsRequested+=num==SOUND;
			
						if(!llList2Integer(queueStride, _QUEUE)) {
							clearQueue();
						}
						SoundQueue+=queueStride;
						flagExecQueue=TRUE;
					}
				}
				if(flagExecQueue) {
					execQueue();
				}
			}
		}
		else if(num==SOUND_STOP) {
			if(isTarget(str)) {
				llStopSound();
				clearQueue();
			}
		}
		else if(num == OPTIONS) {
			//save new option(s) from LINKMSG
			list optionsToSet = llParseStringKeepNulls(str, ["~","|"], []);
			integer length = llGetListLength(optionsToSet);
			integer index;
			for(index=0; index<length; ++index) {
				list optionsItems = llParseString2List(llList2String(optionsToSet, index), ["="], []);
				string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
				string optionString = llList2String(optionsItems, 1);
				string optionSetting = llToLower(llStringTrim(optionString, STRING_TRIM));
				integer optionSettingFlag = optionSetting=="on" || (integer)optionSetting;
				integer optionDecInc = !llSubStringIndex(optionSetting, "+") || !llSubStringIndex(optionSetting, "-");
				if(optionItem == "soundmastervolume") {
					if(optionDecInc) {
						OptionSoundVolume+=(float)optionSetting;
					}
					else {
						OptionSoundVolume=(float)optionSetting;
					}
					if(OptionSoundVolume>1.0) {
						OptionSoundVolume=1.0;
					}
					else if(OptionSoundVolume<0.0) {
						OptionSoundVolume=0.0;
					}
					llAdjustSoundVolume(OptionSoundVolume+0.00001); //+0.00001 added because of https://jira.secondlife.com/browse/BUG-139235
				}
				else if(optionItem == "soundmetabroadcast") {OptionSoundMetaBroadcast = optionSettingFlag;}
			}
		}
		else if(num==MEMORY_USAGE) {
			llSay(0,
				"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
				+ ", Leaving " + (string)llGetFreeMemory() + " memory free.\n Max queue length: " + (string)(StatMaxNumberOfQueueEntries/SOUND_QUEUE_STRIDE)
				+ ". Valid SOUND requests: " + (string)StatSoundsRequested + ". Valid SOUND_NC requests: " + (string)StatSoundNcsRequested + ". Items played: " + (string)StatSoundItemsPlayed + "."
			);
		}
	}
	dataserver(key queryid, string data) {
		if(queryid==llList2Key(CurrentNotecardData, _REQUEST_UUID)) {
			integer flagExecQueue=TRUE;
			integer index=llListFindList(SoundQueue, [TYPE_NC, llList2String(CurrentNotecardData, _NAME)]);
			if(!~index) {
				CurrentNotecardData=[];
			}
			else {
				key userUuid=llList2Key(CurrentNotecardData, _USER_UUID);
				if(data==EOF) {
					integer reps=llList2Integer(CurrentNotecardData, _REPS);
					if(!reps) {
						SoundQueue=llDeleteSubList(SoundQueue, index, index+SOUND_QUEUE_STRIDE-1);
					}
					else if(reps>0) {
						reps--;
						SoundQueue=llListReplaceList(SoundQueue, [reps], index+_REPS, index+_REPS);
					}
					if(OptionSoundMetaBroadcast) {
						//add the length to the meta data
						float totalLength=llList2Float(CurrentNotecardData, _TOTAL_LENGTH);
						CurrentNotecardMetaDataNames+=[TAG_TOTAL_LENGTH, TAG_TOTAL_LENGTH_STRING];
						CurrentNotecardMetaDataValues+=[totalLength, timeStringFromSeconds(llRound(totalLength))];
						list outputList;
						integer metaIndex;
						integer metaLength=llGetListLength(CurrentNotecardMetaDataNames);
						for(metaIndex=0; metaIndex<metaLength; metaIndex++) {
							outputList+=[llList2String(CurrentNotecardMetaDataNames, metaIndex), llList2String(CurrentNotecardMetaDataValues, metaIndex)];
						}
						string output=llList2Json(JSON_OBJECT, outputList);
						integer metaPlaceholderIndex=llListFindList(SoundQueue, [TYPE_META_BROADCAST_PLACEHOLDER, llList2String(CurrentNotecardData, _NAME)]);
						if(~metaPlaceholderIndex) {
							SoundQueue=llListReplaceList(SoundQueue, [TYPE_META_BROADCAST_CURRENT, output, 0.0, 0, 1, 0, 0.0, 0, userUuid], metaPlaceholderIndex, metaPlaceholderIndex+SOUND_QUEUE_STRIDE-1);
						}
						SoundQueue=llListInsertList(SoundQueue, [TYPE_META_BROADCAST_LAST, output, 0.0, 0, 1, 0, 0.0, 0, userUuid], index);
					}
					CurrentNotecardData=[];
				}
				else {
					data=llStringTrim(data, STRING_TRIM);
					if(data=="") {
						//ignore blank lines
						flagExecQueue=FALSE;
					}
					else if(!llSubStringIndex(data, "#")) {
						//ignore comments
						flagExecQueue=FALSE;
					}
					else if(!llSubStringIndex(data, "META|")) {
						if(OptionSoundMetaBroadcast) {
							data=llDeleteSubString(data, 0, 4);
							list allDataList=llParseString2List(data, ["|"], []);
							integer allDataIndex;
							integer allDataLength=llGetListLength(allDataList);
							for(allDataIndex=0; allDataIndex<allDataLength; allDataIndex++) {
								list item=llParseString2List(llList2String(allDataList, allDataIndex), ["="], []);
								string itemName=llToLower(llStringTrim(llList2String(item, 0), STRING_TRIM));
								string itemValue=llStringTrim(llList2String(item, 1), STRING_TRIM);
								integer metaIndex=llListFindList(CurrentNotecardMetaDataNames, [itemName]);
								if(~metaIndex) {
									CurrentNotecardMetaDataValues=llListReplaceList(CurrentNotecardMetaDataValues, [itemValue], metaIndex, metaIndex);
								}
								else {
									CurrentNotecardMetaDataNames+=[itemName];
									CurrentNotecardMetaDataValues+=[itemValue];
								}
							}
						}
						flagExecQueue=FALSE;
					}
					else if(!llSubStringIndex(data, "DO|")) {
						data=llDeleteSubString(data, 0, 2);
						SoundQueue=llListInsertList(SoundQueue, [TYPE_DO, data, 0.0, 0, 1, 0, 0.0, 0, userUuid], index);
						flagExecQueue=TRUE;
					}
					else {
						if(!llSubStringIndex(data, "SOUND|")) {
							data=llDeleteSubString(data, 0, 5);
						}
						list defaultValues=llList2List(CurrentNotecardData, 0, SOUND_QUEUE_STRIDE-1);
						defaultValues=llListReplaceList(defaultValues, [1], _PRELOAD, _PRELOAD);
						defaultValues=llListReplaceList(defaultValues, [0], _REPS, _REPS);
						defaultValues=llListReplaceList(defaultValues, [TYPE_SOUND], _TYPE, _TYPE);
						list queueStride=getParams(convertOldNcSyntax(data), defaultValues);
						if(queueStride) {
							SoundQueue=llListInsertList(SoundQueue, queueStride, index);
							float totalLength=llList2Float(CurrentNotecardData, _TOTAL_LENGTH);
							totalLength+=llList2Float(queueStride, _LENGTH)*((float)llList2Integer(queueStride, _REPS)+1.0);
							CurrentNotecardData=llListReplaceList(CurrentNotecardData, [totalLength], _TOTAL_LENGTH, _TOTAL_LENGTH);
						}
						flagExecQueue=TRUE;
					}
					//read next line
					readNotecard();
				}
				if(flagExecQueue) {
					execQueue();
				}
			}
		}
	}
	on_rez(integer param) {
		llResetScript();
	}
	
	timer() {
		Playing=FALSE;
		llSetTimerEvent(0.0);
		execQueue();
	}
}
