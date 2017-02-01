--this script was written by hubcapp and is based off of i_o_l's timer script
--increased functionality is thanks to memory addresses found at http://datacrystal.romhacking.net/wiki/Super_Mario_Bros.:RAM_map

personalBests = {
{0,0,0,0}, -- W1, {1-1,1-2,1-3,1-4}
{0,0,0,0}, -- W2
{0,0,0,0}, -- W3
{0,0,0,0}, -- W4
{0,0,0,0}, -- W5
{0,0,0,0}, -- W6
{0,0,0,0}, -- W7
{0,0,0,0}  -- W8
};

--"personalBests" are stored as frames per level, separated by commas in the table above.

--levels are defined as the amount of frames between when mario first takes control (first frame after the black title screen of each level)
--  and the end of the title screen for the next level, up until 8-4 where the end of the level condition is shown in the code below (you hit the axe)

--If you're not sure how to find these, it's the number after the time in splits displayed by this script
--Leave levels that you are not using for the run equal to 0 (e.g., you could set only 1-1, 1-2, 4-1, 4-2, 8-1, 8-2, 8-3, and 8-4)

--Some examples are below
--If you want to try and race against them, uncomment them by (re)moving the --[[ and --]] lines
--whichever uncommented table is executed last will be the one active for the run, so you can leave your pb table intact above

--Here are some other variables you might want to change
displayXpos = true; --this only applies for 4-2, because as far as I know, that's the only place it's useful

displaySplits = true; --completely disables splits (at top left) if false
    displayFrameOffset = true; --this shows how many framerules you're ahead/behind compared to your personal best on a single level
        offsetSplitsUnits = "seconds"; --valid values are "frames", "framerules", or "seconds". This is what unit displayFrameOffset is in.
    displayFrames = false; --Always show how many frames it takes you to complete a level, not just when you PB
        framesUnits = "frames"; --valid values are "frames", "framerules", or "seconds". This is what unit displayFrameOffset is in.
    splitsToDisplay = 5; --how many splits to display on screen at once. Should be between 0 and 25 with default values for splitY and timerY to not overlap any other message boxes. 5 is a good value to not block very much on screen (other than score)
    lineColour = "#440000"; --the colour of the seperator bars in splits
    displayCoin2 = true; --display a second coin counter over the word "WORLD" whenever the coin counter is obscured by splits

displayFrameruleCounter = true; --this is the counter at the bottom left that shows how many framerules have elapsed since the console was turned on

displayFrameruleOffset = true; --display total framerule offset in the bottom right for pro players who are consistent enough to manipulate RNG
    offsetUnits = "framerules"; --valid values are "frames", "framerules", or "seconds". This is what unit displayFrameruleOffset is in.

displayAllInfoOnWin = true; --even if you have splits, offsets, frames, etc disabled for the actual run, once you beat the game, we can display them. splitsToDisplay is also set to maxSplits

--[[
--2011 happylee TAS any% splits
--http://tasvideos.org/1715M.html
personalBests = {
{1910,1871,0,0}, -- W1, {1-1,1-2,1-3,1-4}
{0,0,0,0}, -- W2
{0,0,0,0}, -- W3
{2227,1725,0,0}, -- W4
{0,0,0,0}, -- W5
{0,0,0,0}, -- W6
{0,0,0,0}, -- W7
{3046,2143,2101,2648}  -- W8
};
--]]
--[[
--2012 happylee TAS warpless splits
--http://tasvideos.org/1962M.html
personalBests = {
{1910,2645,1744,1618}, -- W1, {1-1,1-2,1-3,1-4}
{1996,3489,2038,1618}, -- W2
{1975,2017,1660,1618}, -- W3
{2227,2670,1639,1870}, -- W4
{1975,2080,1660,1618}, -- W5
{2017,2122,1765,1621}, -- W6
{1912,3489,2038,2038}, -- W7
{3046,2143,2101,2648}  -- W8
};
--]]
--[[
--2014 mars608 & happylee walkathon
--http://tasvideos.org/2676M.html
personalBests = {
{2309,3300,2286,2374}, -- W1, {1-1,1-2,1-3,1-4}
{2670,3573,3046,2332}, -- W2
{2794,2815,2227,2332}, -- W3
{3130,3449,3193,2689}, -- W4
{2647,2794,2227,2332}, -- W5
{2773,2983,2458,2416}, -- W6
{2542,3573,3046,3025}, -- W7
{4621,2920,2794,3437}  -- W8
};
--]]

--2017 my sum of bests
personalBests = {
{2158,2102,0,0}, -- W1, {1-1,1-2,1-3,1-4}
{0,0,0,0}, -- W2
{0,0,0,0}, -- W3
{2269,2523,0,0}, -- W4
{0,0,0,0}, -- W5
{0,0,0,0}, -- W6
{0,0,0,0}, -- W7
{3605,0,0,0}  -- W8
};

--if it matters to you, every split actually happens 5 frames after the framerule rolls over from 20 back to 0 (except for 8-4)

------------------------------------------------------------------------

timerX = 256; --pixels from the left that the time string should stop at
timerY = 220; --pixels from the top to draw frame counter and time string
totalSeconds = 0; seconds = 0; minutes = 0; hours = 0;
 
bowser8 = false;
hitAxe = false;
once = false; --this is used so we don't run the code for detecting the axe was hit more than once
finalSeconds = 0; finalMinutes = 0; finalHours = 0;
startFrame = -1;
gameOver = false;
noContinue = false;
levelChanged = false;
offScript = false;
lastWorld = 1;
lastLevel = 1;

splitY = 8; --y coordinate at which to put the first split. best if this is a multiple of 8 to overlap MARIO and SCORE cleanly
maxSplits = 25; --this is the maximum amount of splits that will fit on screen
splitArray = {}; --holds split times (and how wide they are in pixels)
frameArray = {}; --holds split times in "frames since start"
worldArray = {}; --holds the name of the world just completed

keyPressed = false; --used to prevent toggling multiple times if user doesn't do a frame perfect toggle
nesClockSpeed = (39375000/655171); --(39375000/655171) is ~60.098, the "true clock speed" of the NES
frameSecond = 1/nesClockSpeed; --how many seconds each frame takes (0.016 ish)

function sanityCheck()
    if offsetSplitsUnits ~= "framerules" and offsetSplitsUnits ~= "frames" and offsetSplitsUnits ~= "seconds" then
        return "offsetSplitsUnits is invalid";
    end;
    if framesUnits ~= "framerules" and framesUnits ~= "frames" and framesUnits ~= "seconds" then
        return "framesUnits is invalid";
    end;
    if offsetUnits ~= "framerules" and offsetUnits ~= "frames" and offsetUnits ~= "seconds" then
        return "offsetUnits is invalid";
    end;
    return "sane";
end;
sanityStatus = sanityCheck();

function personalBestsToFlat(personalBests) --converts "user friendly" personal best array to a flat array which is easier to work with
    local personalBestsFlat = {};
    for i=1,8 do
        for j=1,4 do
            if personalBests[i][j] ~= 0 then
                personalBestsFlat[#personalBestsFlat + 1] = personalBests[i][j];
            end;
        end;
    end;
    
    return personalBestsFlat;
end;

personalBestsFlat = personalBestsToFlat(personalBests);
personalBestsSet = true;
if #personalBestsFlat == 0 then --user has not configured any personal best times
    personalBestsSet = false;
end;

function round(num, idp)
    local mult = 10^(idp or 0);
    return math.floor(num * mult) / mult;
end;

function numberPixelLength(number)
    if number == 0 then
        return 1*6;
    end;

    length = 0;
    if number < 0 then
        number = number * -1; --this math doesn't work on negative numbers
        length = length + 5; --negative sign is 5 pixels wide
    end;
    return math.floor(math.log10(number)+1)*6 + length; --conveniently, all numbers characters are 6 pixels wide (including spacing)
end;

function formatSplitString(split, unit, addPlus)
    local pixelWidth = 0;
    local splitString = "";
    if (split >= 0) and addPlus then
        splitString = splitString .. "+";
        pixelWidth = pixelWidth + 6; -- + sign is 6 px wide
    end;
    if unit == "frames" then
        splitString = splitString .. split;
        pixelWidth = pixelWidth + numberPixelLength(split);
    else
    if unit == "framerules" then
        if split % 21 == 0 then --framerule split is an integer
            splitString = splitString .. (split/21);
            pixelWidth = pixelWidth + numberPixelLength(split/21);
        else
            splitString = splitString .. (math.floor(split/21.0)) .. ";" .. split %21; --framerules;additional_frames
            pixelWidth = pixelWidth + numberPixelLength(math.floor(split/21.0)) + 3 + numberPixelLength(split%21);
        end;
    else
    if unit == "seconds" then
        splitString = splitString .. string.format("%0.2f",split * frameSecond);
        pixelWidth = pixelWidth + numberPixelLength(math.floor(split * frameSecond)) + 3 + 12; --integer part gets numberPixelLength, 3 px for the ., the 2 fraction digits are constant width
    end;--seconds
    end;--framerules
    end;--frames
    return {["pixelWidth"]=pixelWidth, ["split"]=splitString};
end;

function formatTimerString(hours, minutes, seconds)
    timerString = "";
    pixelWidth = 0; --we assume numbers are 6px wide and punctuation is 3px wide based on current release 2.2.3 of fceux

    --Hours
    if hours > 0 then --don't need to display hours at all if we're under 60 minutes
        timerString = timerString .. string.format("%.0f", hours);
        pixelWidth = pixelWidth + numberPixelLength(hours);

        if minutes < 10 then
            timerString = timerString .. ":0";
            pixelWidth = pixelWidth + 9;
        else
            timerString = timerString .. ":";
            pixelWidth = pixelWidth + 3;
        end;
    end;
    
    --Minutes
    timerString = timerString .. string.format("%.0f",minutes);
    if minutes < 10 then
        pixelWidth = pixelWidth + 6;
    else
        pixelWidth = pixelWidth + 12;
    end;

    --Seconds
    if seconds < 10 then
        timerString = timerString .. ":0" .. string.format("%0.2f",seconds); --displaying the timer, we need a leading zero on the seconds
    else
        timerString = timerString .. ":"  .. string.format("%0.2f",seconds); --we do not need a leading zero on the seconds
    end;
    pixelWidth = pixelWidth + 30; --1*3+2*6+1*3+2*6 :00.00

    return {["pixelWidth"]=pixelWidth, ["timer"]=timerString};
end;

coinColour = {0,0,0,0};
coinColourNot = {0,0,0,0};
function coinColours()
    local r,g,b,palette = emu.getscreenpixel(92, 28, true); --reaches underneath the lua gui.text and finds the rgb value of the coin flasher
    coinColour = {r,g,b,255};
    r,g,b,palette = emu.getscreenpixel(92, 28, false); --doesn't go underneath the lua gui.text in order to figure out if it's covered up or not.
    coinColourNot = {r,g,b,255};
    return 0;
end;

while true do
------------------------------------------------------------------------
    --toggle optional overlays
    --these only work on windows. they do not work on linux or mac as of 2.2.3. Just edit the variables at the top until the magic day that FCEUX devs implement this feature for us.
    --if you want to remap these keys, a list of valid key names is available at http://www.fceux.com/web/help/fceux.html?LuaFunctionsList.html (ctrl-F "leftbracket")
    ---- toggle framerule counter
    if input.get().F4 and keyPressed == false then
        displayFrameruleCounter = not(displayFrameruleCounter);
        keyPressed = true;
    end;
    ---- display splits
    if input.get().F6 and keyPressed == false then
        displaySplits = not(displaySplits);
        keyPressed = true;
    end;
    ---- display xpos on 4-2
    if input.get().F8 and keyPressed == false then
        displayXpos = not(displayXpos);
        keyPressed = true;
    end;
    ---- display frame offset in splits
    if input.get().F9 and keyPressed == false then
        displayFrameOffset = not(displayFrameOffset);
        keyPressed = true;
    end;
    ---- display total frame offset
    if input.get().rightbracket and keyPressed == false then
        displayFrameruleOffset = not(displayFrameruleOffset);
        keyPressed = true;
    end;
------------------------------------------------------------------------

    --game related variables
    state = memory.readbyte(0x0770); --0 = title screen, 1 = playing the game, 2 = rescued toad/peach, 3 = game over
    frameruleCounter = math.floor(movie.framecount()/21.0);
    frameruleFraction = memory.readbyte(0x077F); --value between 0 and 20
    gameTimer = memory.readbyte(0x07F8)*100 + memory.readbyte(0x07F9)*10 + memory.readbyte(0x07FA);
    world = memory.readbyte(0x075F)+1;
    level = memory.readbyte(0x0760)+1;
    if (level > 2 and (world == 1 or world == 2 or world == 4 or world == 7)) then --the cute animation where you go into a pipe before starting the level counts as a level internally
        level = level - 1; --for worlds with that cutscene, we have to subtract off that cutscene level
    end;

    --player related variables
    xpos = memory.readbyte(0x03AD); --number of pixels between mario (or luigi...) and the left side of the screen
    --xsub = memory.readbyte(0x0400); --current subpixel
    lives = memory.readbyte(0x075A)+1;

    -- set timer start frame
    if startFrame == -1 and world == 1 and level == 1 and gameTimer == 400 then --on title screen, values are world 1-1, gameTimer 401. when timer goes to 400, we've started the timer and don't need to set it again until game over or console reset
        startFrame = movie.framecount();
    end;

    -- calculate hour:minute:second
    totalFrames =  movie.framecount() - startFrame -1;
    totalSeconds = totalFrames/nesClockSpeed;
    seconds = totalSeconds % 60;
    minutes = math.floor(totalSeconds / 60) % 60;
    hours = math.floor(totalSeconds / 3600);
    
    --warn the user about something they did wrong
    if state == 0 and startFrame == -1 then
        if personalBestsSet == false and displayFrameOffset == true then -- tell the user to set up their PBs if they want that feature to work...!
            gui.text(66,timerY-8,"personalBests not set!")
            gui.text(55,timerY,  "edit the script near line 4")
        end;
        if sanityStatus ~= "sane" then -- tell the user they made a typo in one of the settings
            gui.text(80,100,sanityStatus);
            gui.text(66,108,"check your script settings");
        end;
    end;
    
    if state == 3 then --GAME OVER, also detectable if lives == 256
        gameOver = true;
    end;
    
    if gameOver and state == 1 and world == 1 and level == 1 then --the player gameOvered recently and then restarted on world 1-1, so they didn't choose to continue their run by pressing Start and A simultaneously
        noContinue = true;
    end;
    
------------------------------------------------------------------------
    -- (player resets the console) or (player game overs and doesn't continue), need to reset
    if movie.framecount() == 0 or noContinue then
        seconds = 0; minutes = 0; hours = 0;
        finalSeconds = 0; finalMinutes = 0; finalHours = 0;
        bowser8 = false;
        hitAxe = false;
        once = false;
        gameOver = false;
        noContinue = false;
        offScript = false;
        startFrame = -1;
        splitArray = {};
        worldArray = {};
        frameArray = {};
        gui.text(0,0,"");
    end;
    
    -- display starting frame for the first 240 frames of game play (about 4 seconds)
    if (totalFrames < 240 and startFrame ~= -1) then
        if displayFrameruleCounter then
            gui.text(0,timerY-8,startFrame);
        else
            gui.text(0,timerY,startFrame);
        end;
    end;

    -- display framerules elapsed
    if displayFrameruleCounter then
        gui.text(0,timerY,frameruleCounter);
    end;
    
    -- display mario's xpos for wrong warp on 4-2
    if displayXpos then
        if (world == 4 and level == 2) then
            if (xpos < 100) then
                guiX = 239;
            else
                guiX = 236;
            end;
            gui.text(235, 16, "xpos");
            gui.text(guiX, 24,  xpos);
        end;
    end;
    
    -- stop timer
    ----detect if bowser is on the screen and you are in world 8
    if world == 8 then
        for i=0,5 do
            if memory.readbyte((0x0016)+i) == 0x2d then
                bowser8 = true;
            end;
        end;
    end;

    ----detect if you hit the axe on 8-4 and lock the timer's value
    if bowser8 and memory.readbyte(0x01ED) == 242 and xpos > 210 and once == false then
        hitAxe = true;
        once = true;
        finalSeconds = round(seconds, 2);
        finalMinutes = minutes;
        finalHours = hours;
        splitArray[#splitArray + 1] = formatTimerString(finalHours,finalMinutes,finalSeconds);
        worldArray[#worldArray + 1] = world .. "-" .. level;
        
        if displayAllInfoOnWin then
            splitsToDisplay = #splitArray; --may as well display as many splits as we can now that the game is over and we're not very worried about blocking anything on screen.
            displayFrames = true; --also display as much information as possible
            displayFrameOffset = true;
            displaySplits = true;
        end;
        
        local levelFrames;
        local newPB;
        levelFrames = totalFrames-frameArray[#frameArray]["frame"]; --calculate how many frames 8-4 took
        newPB = (levelFrames < personalBests[splitWorld][splitLevel]) and not(offScript); --true if less frames were just taken in 8-4 than whatever is recorded in the personalBests table, and also the user has set up PB times
        frameArray[#frameArray + 1] = {["frame"]=totalFrames, ["newPB"]=newPB, ["pbFrameOffset"]=levelFrames - personalBests[splitWorld][splitLevel], ["offScript"]=offScript};
    end;

    ----display timer
    if hitAxe then
        timerString = formatTimerString(finalHours,finalMinutes,finalSeconds);
        gui.text(timerX - timerString["pixelWidth"], timerY, timerString["timer"]);
    else
        if startFrame ~= -1 then
            timerString = formatTimerString(hours,minutes,seconds);
            gui.text(timerX - timerString["pixelWidth"], timerY, timerString["timer"]);
        else
            gui.text(timerX - 36, timerY, "0:00.00");
        end;
    end;

    -- detect split
    if levelChanged == false then
        levelChanged = (world ~= lastWorld or level ~= lastLevel); --true if just level changes basically, not aware of any warp zone that warps from x-z to y-z, and the ends of worlds always goes from x-4 to y-1
        splitWorld = lastWorld;
        splitLevel = lastLevel;
        splitState = lastState;
    end;
    if levelChanged and memory.readbyte(0x0772) == 2 then --0772 == 2 makes it split after the level's title screen when going into a warp pipe
        levelChanged = false;
        timerString = formatTimerString(hours,minutes,seconds);
        if state == 1 then
            splitArray[#splitArray + 1] = timerString;
            if splitState ~= 0 then --0 is demo screen
                worldArray[#worldArray + 1] = splitWorld .. "-" .. splitLevel;
                
                if personalBests[splitWorld][splitLevel] == 0 then --user has gone "off script" and has no PB for this level. This can happen if they have an incomplete PB table (never beat the game?) or their PB table is based off any% and they just went to 1-3 e.g.
                    offScript = true; --this will stop us from "!!set new pb!!" and displaying meaningless framerule offsets
                end;

                --calculate how many frames the last level took
                local levelFrames;
                local newPB;
                if #frameArray > 0 then
                    levelFrames = totalFrames-frameArray[#frameArray]["frame"];
                else
                    levelFrames = totalFrames;
                end;
                --check if this split qualifies as a personal best
                newPB = (levelFrames < personalBests[splitWorld][splitLevel]) and not(offScript); --true if less frames were just taken in the last level than whatever is recorded in the personalBests table, and also the user has set PB times

                frameArray[#frameArray + 1] = {["frame"]=totalFrames, ["newPB"]=newPB, ["pbFrameOffset"]=levelFrames - personalBests[splitWorld][splitLevel], ["offScript"]=offScript};
            else
                worldArray[#worldArray + 1] = world .. "-C"; --game continue
                local waldo = -1;
                for i=1,#worldArray do --find where in frameArray you were on "world-1" last to determine how much time you just lost from gameOvering vs never dying
                    if worldArray[i] == world .. "-1" then
                        waldo = i-1;
                        break; --got i, get out
                    end;
                end;
                if waldo == -1 then
                    waldo = #worldArray-1;
                end;

                frameArray[#frameArray + 1] = {["frame"]=totalFrames, ["newPB"]=false, ["pbFrameOffset"]=totalFrames - frameArray[waldo]["frame"], ["offScript"]=offScript}; --second part is whether or not it's a PB... I hope you're not trying to PB your game continues, and there's no place for them in the PB table anyway. the offset becomes how much time you've lost.
                gameOver = false; --game continues
            end;
        end;
    end;
    
    -- display splits and frame offsets
    if displaySplits and #splitArray > 0 then --display at least 8-1 00:00.00
        local iBegin;
        local iEnd = #splitArray;

        if #splitArray >= splitsToDisplay or splitsToDisplay > maxSplits then
            iBegin = #splitArray - splitsToDisplay; --we have more splits than we would like to display
            if hitAxe and #splitArray > maxSplits then
                
                iBegin = ((math.floor((frameruleCounter - math.floor(frameArray[#frameArray]["frame"]/21.0))/9.0)+(#splitArray-maxSplits)) % #splitArray); --cycle through splits every 9 framerules so that all of them are eventually displayed. Even if you're really bad and game_over-continue 100 times.
                iEnd = iBegin+maxSplits;
            end;
        else
            iBegin = 0; --we don't have a lot of splits yet, less than splitsToDisplay anyway.
        end;

        --fix iEnd in case user put a number greater than maxSplits
        if splitsToDisplay > maxSplits and not(hitAxe) then
            iEnd = maxSplits;
        end;
        for i=iBegin,iEnd do --draw splitsToDisplay splits
            local index = ((i-1) % #splitArray)+1;

            gui.text(00, splitY+(i-iBegin)*8, worldArray[index]); --display 8-1
            gui.text(17, splitY+(i-iBegin)*8, " ", nil, lineColour); --separator bar, 3px before the timer
            gui.text(20, splitY+(i-iBegin)*8, splitArray[index]["timer"]); --display 00:00.00
            
            if (displayFrames or displayFrameOffset or frameArray[index]["newPB"]) then
                if sanityStatus ~= "sane" then
                    gui.text(80,100,sanityStatus);
                    gui.text(66,108,"check your script settings");
                end;

                --figure out what the frame text will look like. (2100 vs !!2100!!), and where to grab the 2100 from
                if (displayFrames or frameArray[index]["newPB"]) or (displayFrameruleOffset and frameArray[index]["offScript"]) then
                    local curFrameSplit;
                    if index > 1 then --subtract old total from new total
                        curFrameSplit = frameArray[index]["frame"]-frameArray[index-1]["frame"];
                    else
                        curFrameSplit = frameArray[index]["frame"] --we're on the first item, so just return it
                    end;
                    if frameArray[index]["newPB"] then
                        frameText = "!!" .. curFrameSplit .. "!!"; --if it's a PB, wrap it in excitement
                        if framesUnits ~= "frames" and displayFrames then --need to display frame count anyway, so user can put it in their PB table
                            frameText = formatSplitString(curFrameSplit,framesUnits, false)["split"] .. " " .. frameText; --display the user's preferred split format in front of frames for PB
                        end;
                    else
                        if displayFrameruleOffset and frameArray[index]["offScript"] then
                            frameText = curFrameSplit; --display in frames no matter what for people trying to fill in their PB table
                        else
                            frameText = formatSplitString(curFrameSplit,framesUnits, false)["split"]; --else just normal amount of enthusiasm
                        end;
                    end;
                end;

                --display what we figured out about pbFrameOffset
                local additionalWidth = 0;
                if displayFrameOffset then --displaying at least the frame offset. Timer will look like "8-1 00:00.00 +21" (so far)
                    gui.text(20+splitArray[index]["pixelWidth"],splitY+(i-iBegin)*8, " ", nil, lineColour); --bar
                    if not(frameArray[index]["offScript"]) then
                        local formattedSplit = formatSplitString(frameArray[index]["pbFrameOffset"], offsetSplitsUnits, true);
                        gui.text(20+splitArray[index]["pixelWidth"]+3, splitY+(i-iBegin)*8, formattedSplit["split"]);
                        additionalWidth = additionalWidth + 3 + formattedSplit["pixelWidth"];
                    else
                        gui.text(20+splitArray[index]["pixelWidth"]+3, splitY+(i-iBegin)*8,"X"); --an X to indicate to users who have frameOffsets turned on that the frameOffset for this split has been deemed "invalid"
                        additionalWidth = additionalWidth + 3 + 6; --" X"
                    end;
                end;
                --display how many frames it took to complete the level, and PB frame number
                if (displayFrames or frameArray[index]["newPB"]) or (displayFrameruleOffset and frameArray[index]["offScript"]) then --displaying frames. Timer looks like "8-1 00:00.00 +21 2100". Need to display frames
                    gui.text(20+splitArray[index]["pixelWidth"]+additionalWidth,splitY+(i-iBegin)*8, " ", nil, lineColour); --bar
                    gui.text(20+splitArray[index]["pixelWidth"]+3+additionalWidth, splitY+(i-iBegin)*8, frameText);
                end;
            end; --displaying more than just 8-1 00:00.00
        end; --draw splits Loop

        -- if splits are displayed, and we have all the options enabled, it's pretty easy to cover up the coin counter
        -- it's not really a big deal if we do, but the option should be there to show it.
        -- display a second coin counter over the word "WORLD" whenever the coin counter is obscured by splits
        if displayCoin2 then
            emu.registerbefore(coinColours); --check if coin is obscured, and what colour it is

            if coinColour[1] ~= coinColourNot[1] or coinColour[2] ~= coinColourNot[2] or coinColour[3] ~= coinColourNot[3] then --check if the pixel at (92, 28) is obscured by lua text. If it is, display second coin counter.
                local coins = memory.readbyte(0x075E);
                if coins < 10 then
                    coins = "0" .. coins;
                end;
                gui.text(153,16," ",nil,coinColour);
                gui.text(157,16,"X" .. coins);
            end;
        end;
    end; --display splits
    
    -- display total framerule offset in the bottom right for pro players who are consistent enough to manipulate RNG
    if displayFrameruleOffset then
        if not(offScript) then
            if sanityStatus ~= "sane" then
                gui.text(80,100,sanityStatus);
                gui.text(66,108,"check your script settings");
            end;
            local formattedSplit
            if #frameArray > 0 then
                --find total frameruleOffset
                local frameruleOffset = 0;
                for i=1,#frameArray do
                    frameruleOffset = frameruleOffset + frameArray[i]["pbFrameOffset"];
                end;
                formattedSplit = formatSplitString(frameruleOffset, offsetUnits, true);
                gui.text(timerX - formattedSplit["pixelWidth"], timerY-8, formattedSplit["split"]);
            end;
        else
            gui.text(timerX - 6, timerY-8, "X");
        end;
    end;

------------------------------------------------------------------------
    --display toggle notifications last
    if keyPressed == true then
        if input.get().F4 then
            if displayFrameruleCounter then
                gui.text(0,timerY-8,"fr counter on");
            else
                gui.text(0,timerY-8,"fr counter off");
            end;
        end;
        if input.get().F6 then
            if displaySplits then
                gui.text(0,timerY-8,"splits on");
            else
                gui.text(0,timerY-8,"splits off");
            end;
        end;
        if input.get().F8 then
            if displayXpos then
                gui.text(0,timerY-8,"xpos on");
            else
                gui.text(0,timerY-8,"xpos off");
            end;
        end;
        if input.get().F9 then
            if displayFrameOffset then
                gui.text(0,timerY-8,"fr offset on");
            else
                gui.text(0,timerY-8,"fr offset off");
            end;
        end;
        if input.get().rightbracket then
            if displayFrameruleOffset then
                gui.text(0,timerY-8,"total offset on");
            else
                gui.text(0,timerY-8,"total offset off");
            end;
        end;
    end;
    ---- release key press
    if not(input.get().rightbracket) and not(input.get().F4) and not(input.get().F6) and not(input.get().F8) and not (input.get().F9) then
        keyPressed = false;
    end;
------------------------------------------------------------------------

    lastWorld = world;
    lastLevel = level;
    lastState = state;
    emu.frameadvance();
end;
