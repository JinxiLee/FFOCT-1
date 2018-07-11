function handles=acqOCT(handles,i)
% Funciton to acquire OCT only images. Parameters are specified into the
% GUI and carried here by handles struct. OCT trigger is done by the
% National Instrument DAQ in order to synchronize the piezo and the camera.

global SignalDAQ acq_state
acq_state=1;

handles.save.t = datestr(now,'yyyy_mm_dd_HH_MM_ss');
mkdir([handles.save.path '\' handles.save.t ])

set(handles.octCam.vid, 'TriggerFrameDelay', 10) % We leave the first 10 frames because the camera is not stable

switch handles.exp.piezoMode
    case 1 % Direct image only
        handles.exp.FramesPerTrigger=handles.octCam.Naccu*handles.save.Noct;
        set(handles.octCam.vid, 'FramesPerTrigger', handles.exp.FramesPerTrigger, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,handles.exp.FramesPerTrigger)
        [data,handles.save.timeOCT]=getdata(handles.octCam.vid,handles.exp.FramesPerTrigger,'double');
        stop(handles.octCam.vid);
        stop(handles.DAQ.s);
        if handles.save.allraw
            saveAsTiff(squeeze(data),'all_raw','adimec',handles)
        end
        if handles.save.direct
            direct=zeros(size(data,1),size(data,2),handles.save.Noct);
            for i=1:handles.save.Noct
                direct(:,:,i)=mean(data(:,:,1,(i-1)*handles.octCam.Naccu+1:i*handles.octCam.Naccu),4);
            end
            saveAsTiff(direct,'direct','adimec',handles)
        end
    case 2 % Two phases imaging
        handles.exp.FramesPerTrigger=2*handles.octCam.Naccu*handles.save.Noct;
        set(handles.octCam.vid, 'FramesPerTrigger', handles.exp.FramesPerTrigger, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,handles.exp.FramesPerTrigger)
        [data,handles.save.timeOCT]=getdata(handles.octCam.vid,handles.exp.FramesPerTrigger,'double');
        stop(handles.octCam.vid);
        stop(handles.DAQ.s);
        imTomo=zeros(size(data,1),size(data,2),handles.save.Noct);
        for i=1:handles.save.Noct
            imTomo(:,:,i)=abs(mean(data(:,:,1,2*(i-1)*handles.octCam.Naccu+1:2:2*i*handles.octCam.Naccu),4)-mean(data(:,:,1,2*(i-1)*handles.octCam.Naccu+2:2:2*i*handles.octCam.Naccu),4));
        end
        if handles.save.allraw
            saveAsTiff(squeeze(data),'all_raw','adimec',handles)
        end
        if handles.save.direct
            direct=zeros(size(data,1),size(data,2),handles.save.Noct);
            for i=1:handles.save.Noct
                direct(:,:,i)=mean(data(:,:,1,2*(i-1)*handles.octCam.Naccu+1:2:2*i*handles.octCam.Naccu),4);
            end
            saveAsTiff(direct,'direct','adimec',handles)
        end
        if handles.save.amplitude
            saveAsTiff(imTomo,'tomo','adimec',handles)
        end
    case 3 % 4 phase imaging
        handles.exp.FramesPerTrigger=4*handles.octCam.Naccu*handles.save.Noct;
        set(handles.octCam.vid, 'FramesPerTrigger', handles.exp.FramesPerTrigger, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,handles.exp.FramesPerTrigger)
        [data,handles.save.timeOCT]=getdata(handles.octCam.vid,handles.exp.FramesPerTrigger,'double');
        stop(handles.octCam.vid);
        stop(handles.DAQ.s);
        I1=zeros(size(data,1),size(data,2),handles.save.Noct);
        I2=I1;
        I3=I1;
        I4=I1;
        for i=1:handles.save.Noct
            I1(:,:,i)=double(mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+1:4:4*i*handles.octCam.Naccu),4));
            I2(:,:,i)=double(mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+2:4:4*i*handles.octCam.Naccu),4));
            I3(:,:,i)=double(mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+3:4:4*i*handles.octCam.Naccu),4));
            I4(:,:,i)=double(mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+4:4:4*i*handles.octCam.Naccu),4));
        end
        imAmplitude=0.5*sqrt((I4-I2).^2+(I1-I3).^2);
        imPhase=angle((I4-I2)+1i*(I3-I1));
        if handles.save.allraw
            saveAsTiff(squeeze(data),'all_raw','adimec',handles)
        end
        if handles.save.direct
            direct=zeros(size(data,1),size(data,2),handles.save.Noct);
            for i=1:handles.save.Noct
                direct(:,:,i)=mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+1:4:4*i*handles.octCam.Naccu),4);
            end
            saveAsTiff(direct,'direct','adimec',handles)
        end
        if handles.save.amplitude
            saveAsTiff(imAmplitude,'amplitude','adimec',handles)
        end
        if handles.save.phase
            saveAsTiff(imPhase,'phase','adimec',handles)
        end
    case 4 % 5 phases
    case 5
    case 6
        % First take tome image with 5 accumulations
        Naccu=handles.octCam.Naccu;
        handles.octCam.Naccu=5;
        handles.exp.piezoMode=2;
        [dataOut, handles]=oct_2phases(handles);
        handles=drawInGUI(dataOut,2,handles);
        if handles.save.amplitude
            saveAsTiff(dataOut,'tomo','adimec',handles)
        end
        if handles.save.repeat && handles.save.correctDrift
            if mod(i,10)==0
                handles.dffoct.target = dataOut;
                if i~=1
                    disp('autofocus in progress');
                    handles = autofocus(handles);
                end
            end
        end
        handles.octCam.Naccu=Naccu;
        
        % Then take DFFOCT and compute it
        handles.exp.piezoMode=1;
        [direct, handles]=oct_direct(handles);
        [dffoct, handles]=dffoct_gpu(direct, handles);
        handles=drawInGUI(dffoct,6,handles);
        imwrite(dffoct,[handles.save.path '\' handles.save.t '\' sprintf('dffoct_plane_%d.tif',i)]);
        if handles.save.allraw
            saveAsTiff(direct,sprintf('direct_plane_%d',i),'adimec',handles)
        end
        saveParameters(handles)
        
        % Put back the initial mode
        handles.exp.piezoMode=6;
    case 7
        handles.exp.FramesPerTrigger=handles.octCam.Naccu*handles.save.Noct;
        set(handles.octCam.vid, 'FramesPerTrigger', handles.exp.FramesPerTrigger, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,5*handles.exp.FramesPerTrigger)
        [direct,handles.save.timeOCT,~]=getdata(handles.octCam.vid,handles.exp.FramesPerTrigger,'double');
        if handles.save.direct
            saveAsTiff(direct,'direct','adimec',handles)
        end
        stop(handles.octCam.vid);
        stop(handles.DAQ.s);
end

set(handles.octCam.vid, 'TriggerFrameDelay', 0)

acq_state=0;