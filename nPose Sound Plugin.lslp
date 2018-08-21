key ncNumOfLines;
string thisSoundNC;
list eachSoundsList;
list timerList;
float volume;
float timerValue;
string loopEnable;
integer lineCount;
key thisLineKey;
integer numOfNCLines;
integer lineNum;

list SeatedAvs(){
    list avs;
    integer linkcount = llGetNumberOfPrims();
    integer n;
    for (n = linkcount; n >= 0; n--){
        key id = llGetLinkKey(n);
        if (llGetAgentSize(id) != ZERO_VECTOR){
            avs = [id] + avs;
        }else{
            return avs;
        }
    }
    return [];
}

getNumOfLines()
{
    ncNumOfLines = llGetNumberOfNotecardLines(thisSoundNC);
}

preLoadSounds(integer PrePlayLine)
{
    key PrePlayKey = llList2Key(eachSoundsList, PrePlayLine);
    if(PrePlayKey != NULL_KEY)
    {
        llPreloadSound(llList2Key(eachSoundsList, PrePlayLine));
    }
}

playThisSound(integer lineToPlay)
{
    key thisKey = llList2Key(eachSoundsList, lineToPlay);
    if(thisKey != NULL_KEY)
    {
        llPlaySound(llList2Key(eachSoundsList, lineToPlay), volume);
    }
}

startFirstSound()
{
//    playThisSound(0);
    if (numOfNCLines>1){
        preLoadSounds(1);
    }
    llSetTimerEvent(0.04);
}

default
{
    state_entry()
    {
    }

    link_message(integer sender, integer num, string str, key id){
        if (num == -2345) {
            list params = llParseString2List(str, ["~"], []);
            llSetTimerEvent(0.0);
            llStopSound();
            lineNum = 0;
            thisSoundNC = llList2String(params, 0);
            volume = (float)llList2String(params, 1);
            list loopFlag = llParseString2List(llList2String(params, 2), ["="],[]);
            if (llList2String(loopFlag, 0)=="looping"){
                loopEnable = llList2String(loopFlag, 1);
            }
            getNumOfLines();
        }else if (num == -2344){
            llSetTimerEvent(0.0);
            llStopSound();
        }
    }
    
    dataserver(key query_id, string data)
    {
        if(query_id == ncNumOfLines)
        {
            numOfNCLines = (integer)data;
            lineCount = 0;
            eachSoundsList = [];
            timerList = [];
            thisLineKey = llGetNotecardLine(thisSoundNC, lineCount);
        }
        else if(query_id == thisLineKey)
        {
            if(data != EOF)
            {
                list temp = llParseString2List(data, [","], []);
                eachSoundsList += (key)llList2String(temp, 0);
                timerList += (key)llList2String(temp, 1);
                lineCount++;
                thisLineKey = llGetNotecardLine(thisSoundNC, lineCount);
            }
            else
            {
                startFirstSound();
            }
        }
    }
    timer()
    {
        integer lineToPreload = lineNum + 1;
        playThisSound(lineNum);
        llSetTimerEvent((float)llList2String(timerList, lineNum));
        if(lineNum == numOfNCLines - 1)
        {
            if(loopEnable == "ON")
            {
                lineToPreload = 0;
            }
            else
            {
                lineToPreload = 0;
                llSetTimerEvent(0.0);
            }
        }
        preLoadSounds(lineToPreload);
        lineNum++;
        if(lineNum == numOfNCLines)
        {
            lineNum = 0;
        }
    }
    changed(integer change){
        if (change & CHANGED_INVENTORY){
            llResetScript();
        }
    }
}
