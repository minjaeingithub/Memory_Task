clear all; sca; clc; close all;
Screen('Preference', 'SkipSyncTests', 1);

[subject] = get_subjectinfo();
sfile = create_sbfile(subject, '/_DATA/');

% Port init
daq_id = DaqDeviceIndex;
if ~isempty(daq_id), DaqDConfigPort(daq_id,0,0); end

% Screen init
screens = Screen('Screens');
screenNumber = max(screens);
white = 255*[1 1 1];
black = 0*[1 1 1];
gray = 127*[1 1 1];
 
[window, windowRect] = Screen('OpenWindow', screenNumber, white,[0 0 1024 768]);
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Screen size init
imageLength = windowRect(3)/4;
imageHeight = windowRect(3)/6;
imageDims = [xCenter-imageLength yCenter-imageHeight xCenter+imageLength yCenter+imageHeight];

rng = ('Shuffle');
dsgn = [];
eeg = [];
keys = [];

% keyboard setting
KbName('UnifyKeyNames');
escape = KbName('ESCAPE');
space = KbName('Space');
same = KbName('f'); 
different = KbName('j'); 
% image folder routing
imagePath = [pwd '/WM_images/'];

% matrix design
for i1 = 1:2, % MSK: category?  
    for i2 = 1:2 % same different
        for i3 = 1:200
            dsgn = [dsgn; i1 i2 i3];  
        end
    end
end

dsgn = [randperm(length(dsgn))' dsgn]; 
dsgn = sortrows(dsgn,1);
dsgn(:,1) = [];

% dsgn(i1,8)=event_code;
ListenChar(2);

for i1 = 1:size(dsgn,1)
    [imageNum] = rng_cat_img(dsgn(i1,1));
    getImage = [imagePath num2str(imageNum)]; 
    
    % MSK: event code is moved
    event_code = dsgn(i1,2)*100 + dsgn(i1,1);
    
    % instruct_wait & break
    instruct_wait(window, white, i1, 40, dsgn);

    % warning
    Screen('FillRect', window, white);
    show_fixation(window, 255*[1 0 0]);
    vbl = Screen('Flip',window);
    
    % fixation point
    Screen('FillRect', window, white);
    show_fixation(window, [0 0 0]);
    vbl = Screen('Flip',window,vbl+0.5);

    % images first shown
    imageTex = Screen('MakeTexture',window,imread([getImage '.jpg']));
    Screen('DrawTexture',window, imageTex ,[],imageDims,0);
    vbl = Screen('Flip', window, vbl + 0.4 + 0.2*rand);
    send_event(daq_id,event_code);

    
    % blank interval fixation point
    Screen('FillRect', window, white);
    show_fixation(window, [0 0 0]);
    vbl = Screen('Flip',window,vbl+0.5);
    
    
    % 2nd image presentation
    Screen('FillRect', window, white);
    show_fixation(window, 127*[0 0 0]);

    % diff images shown for respective condition same pic
    if dsgn(i1,2)==1
        cimageNum = imageNum;
        % added MSK
        getImage = [imagePath num2str(cimageNum)]; 


    else % diff images within category
        cur_category = dsgn(i1,1);
        cimageNum = imageNum; %currentimageNum
        if(cimageNum < 10) % == category : 1
            image_set = floor(cimageNum/10) + [0:9];
        else
            image_set = floor(cimageNum/10)*10 + [0:9];
        end
        [a, b] = ismember(cimageNum, image_set);
        image_set(b) = [];
        new_image_set = image_set(randperm(length(image_set)));
        new_image_num = new_image_set(1);
        imageNum = new_image_num;
        dsgn(i1,4) = imageNum;
        
        % added MSK
        getImage = [imagePath num2str(imageNum)]; 
    end
    
    imageTex = Screen('MakeTexture',window,imread([getImage '.jpg']));
    Screen('DrawTexture',window, imageTex ,[],imageDims,0);
    vbl = Screen('Flip', window, vbl + 1.0);
        

    % Get response
    done = 0;
    tbegin = GetSecs;
    while(~done)
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
        kSum = keyCode(same)+ 2*keyCode(different);
        
        if (kSum ~= 0) 
            dsgn(i1,5) = kSum;
            dsgn(i1,6) = secs-tbegin;
            send_event(daq_id, kSum);
            % correct/ incorrect code added
            if ((dsgn(i1,2) == 1) && kSum == 1 || (dsgn(i1,2) == 2) && kSum ==2)
                dsgn(i1,7) = 1;
            else
                dsgn(i1,7) = 0;
            end
            done =1;
        end

        if (secs - tbegin > 2.0)
            send_event(daq_id, 4)
            done = 1;
        end
    end
    
    % retention interval 
    Screen('FillRect', window, white);
    show_fixation(window, 127*[0 0 0]);
    Screen('Flip',window, vbl + 0.5);
    
    WaitSecs(1 + 0.5*rand);
    
    disp('done');
    save(sfile, 'dsgn');
end

% instruct or break the control
instruct_wait(window, white, [], [], []);
    
ListenChar(0);
sca;