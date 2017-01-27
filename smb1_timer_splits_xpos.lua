--this script is based off of i_o_l's timer script
--increased functionality is thanks to memory addresses found at http://datacrystal.romhacking.net/wiki/Super_Mario_Bros.:RAM_map

timerX = 256; --pixels from the left that the time string should stop at
timerY = 220; --pixels from the top to draw frame counter and time string
totalSeconds = 0; seconds = 0; minutes = 0; hours = 0;
 
personalBest = 298.74; --i_o_l's personal best at some point in time
 
bowser8 = false;
hitAxe = false;
once = false; --this is used so we don't run the code for detecting the axe was hit more than once
finalSeconds = 0; finalMinutes = 0; finalHours = 0;
startFrame = -1;
gameOver = false;
noContinue = false;
lastWorld = 1;
lastLevel = 1;

displayFrameruleCounter = true;
displayFrameruleOffset = false;
framerule = 0; --this is the offset manually controlled by players to determine what framerule they're on.

displaySplits = true;
splitY = 8; --y coordinate at which to put the first split
splitsToDisplay = 5; --how many splits to display on screen at once
splitArray = {}; --holds split times
worldArray = {}; --holds the name of the world just completed

displayXpos = true; --this only applies for 4-2, because as far as I know, that's the only place it's useful

keyPressed = false; --used to prevent toggling multiple times if user doesn't do a frame perfect toggle
 
function round(num, idp)
    local mult = 10^(idp or 0);
    return math.floor(num * mult) / mult;
end;

function formatTimerString(hours, minutes, seconds)
    timerString = "";
    pixelWidth = 0; --we assume numbers are 6px wide and punctuation is 3px wide based on current release 2.2.2 of fceux
    
    --Hours
    if hours > 0 then --don't need to display hours at all if we're under 60 minutes
        timerString = timerString .. string.format("%.0f", hours);
        pixelWidth = pixelWidth + math.floor(math.log10(hours)+1)*6 --we're good until the end of time
        
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
    
    return {pixelWidth, timerString};
end;


while true do
	--toggle optional overlays
	--these may or may not work on windows, but they do not work on linux as of 2.2.2. Just edit the variables at the top, except for manual splits which won't work without user input.
	--if you want to remap these keys, a list of valid key names is available at http://www.fceux.com/web/help/fceux.html?LuaFunctionsList.html (ctrl-F "leftbracket")
	---- manually adjust your framerule offset
	if input.get().leftbracket and keyPressed == false then
		framerule = framerule + 0.35;
		keyPressed = true;
    end;
    ---- manually adjust your framerule offset
    if input.get().rightbracket and keyPressed == false then
		framerule = framerule - 0.35;
		keyPressed = true;
    end;
    ---- toggle framerule counter
    if input.get().F4 and keyPressed == false then
		displayFrameRuleCounter = not(displayFrameRuleCounter);
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
    ---- display manual framerule offset
	if input.get().F9 and keyPressed == false then
		displayFrameruleOffset = not(displayFrameruleOffset);
		keyPressed = true;
    end;
    if keyPressed == true then
		if input.get().F4 then
			gui.text(0,100,"toggled framerule counter");
		end;
		if input.get().F6 then
			gui.text(0,100,"toggled splits");
		end;
		if input.get().F8 then
			gui.text(0,100,"toggled xpos");
		end;
		if input.get().F9 then
			gui.text(0,100,"toggled framerule offset");
		end;
    end;
    ---- release key press
	if not(input.get().leftbracket) and not(input.get().rightbracket) and not(input.get().F4) and not(input.get().F6) and not(input.get().F8) and not (input.get().F9) then
		keyPressed = false;
	end;

    --game related variables

    state = memory.readbyte(0x0770); --0 = title screen, 1 = playing the game, 2 = rescued toad/peach, 3 = you're dead
    --framerule = memory.readbyte(0x077F); --value between 0 and 20
    curFramerule = math.floor(movie.framecount()/21.0);
    gameTimer = memory.readbyte(0x07F8)*100 + memory.readbyte(0x07F9)*10 + memory.readbyte(0x07FA);
    world = memory.readbyte(0x075F)+1;
    level = memory.readbyte(0x0760)+1;
    if (level > 2 and (world == 1 or world == 2 or world == 4 or world == 7)) then --the cute animation where you go into a pipe before starting the level counts as a level internally
        level = level - 1; --for worlds with that cutscene, we have to subtract off that cutscene level
    end

    --player related variables
    xpos = memory.readbyte(0x03AD); --number of pixels between mario (or luigi...) and the left side of the screen
    --xsub = memory.readbyte(0x0400); --current subpixel
    lives = memory.readbyte(0x075A)+1;   

    -- set timer start frame
    if startFrame == -1 and world == 1 and level == 1 and gameTimer == 400 then --on title screen, values are world 1-1, gameTimer 401. when timer goes to 400, we've started the timer and don't need to set it again until game over or console reset
        startFrame = movie.framecount();
    end;

    -- calculate hour:minute:second
    totalSeconds = (movie.framecount() - startFrame)/(39375000/655171); --(39375000/655171) is ~60.098, I guess the "true clock speed" of the NES
    seconds = totalSeconds % 60;
    minutes = math.floor(totalSeconds / 60) % 60;
    hours = math.floor(totalSeconds / 3600);
    
    if state == 3 then --GAME OVER, also detectable if lives == 256
        gameOver = true;
    end;
    
    if gameOver and state == 1 and world == 1 and level == 1 then --the player gameOvered recently and then restarted on world 1-1, so they didn't choose to continue their run by pressing Start and A simultaneously
        noContinue = true;
    end;

    -- (player resets the console) or (player game overs and doesn't continue), need to reset 
    if movie.framecount() == 0 or noContinue then
            seconds = 0; minutes = 0; hours = 0;
            finalSeconds = 0; finalMinutes = 0; finalHours = 0;
            bowser8 = false;
            hitAxe = false;
            once = false;
            gameOver = false;
            noContinue = false;
            startFrame = -1;
            splitArray = {};
            worldArray = {};
            gui.text(0,0,"");
    end; 

	-- display framerules elapsed
	if displayFrameruleCounter then
		gui.text(0,timerY,curFramerule); --this is probably not useful. People determine their current frame rule relative to their splits usually.
	end;
	
	-- display manual framerule offset
	if displayFrameruleOffset then
		if framerule > 0.001 then
		  gui.text(timerX-25-6,timerY-8,"+"..string.format("%1.2f",framerule));
		end;
		if framerule < -0.001 then
		  gui.text(timerX-25-5,timerY-8,string.format("%1.2f",framerule));
		end;
		if framerule < 0.001 and framerule > -0.001 then
		  gui.text(timerX-25,timerY-8,"0.00");
		end;
	end;
	
    -- display splits
    if displaySplits then
		if #splitArray > splitsToDisplay then
			for i=#splitArray-splitsToDisplay+1,#splitArray do --draw splitsToDisplay splits
				gui.text(0,splitY+(i-#splitArray+splitsToDisplay)*8,worldArray[i] .. " ");
				gui.text(20,splitY+(i-#splitArray+splitsToDisplay)*8,splitArray[i]);
			end;
		else
			for i=1,#splitArray do --just draw as many splits as we have
				gui.text(0,splitY+i*8,worldArray[i] .. " ");
				gui.text(20,splitY+i*8,splitArray[i]);
			end;
		end;
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
        finalSeconds = round(seconds - 655171/39375000, 2);
        finalMinutes = minutes;
        finalHours = hours;
        splitArray[#splitArray + 1] = formatTimerString(finalHours,finalMinutes,finalSeconds)[2];
        worldArray[#worldArray + 1] = world .. "-" .. level;
        --timeBehindPB = finalMinutes*60 + finalSeconds - personalBest;
    end;

    ----display timer with locked values
    if hitAxe then
        timerString = formatTimerString(finalHours,finalMinutes,finalSeconds);
        gui.text(timerX - timerString[1], timerY, timerString[2]);
    else
        if startFrame ~= -1 then
            timerString = formatTimerString(hours,minutes,seconds);
            gui.text(timerX - timerString[1], timerY, timerString[2]);
        else
            gui.text(timerX - 36, timerY, "0:00.00");
        end;
    end;

    if world ~= lastWorld or level ~= lastLevel then
		timerString = formatTimerString(hours,minutes,seconds);
        if state == 1 then
			splitArray[#splitArray + 1] = timerString[2];
            if lastState ~= 0 then
                worldArray[#worldArray + 1] = lastWorld .. "-" .. lastLevel;
            else
                worldArray[#worldArray + 1] = world .. "-C"; --game continue
                gameOver = false;
            end;
        end;
    end;

    lastWorld = world;
    lastLevel = level;
    lastState = state;
    emu.frameadvance();
end;
