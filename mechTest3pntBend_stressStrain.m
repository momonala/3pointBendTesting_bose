%% This MATLAB Code is written to analyze 'Force vs Displacement' and 'Stress vs Strain' outputs from the Bose WinTest system in 3 point bend testing.  
%principal creator: Mohit Nalavadi (mnalavadi@gmail.com)
%Santa Clara University and NASA Ames Space Biosciences - Bone & Signalling Lab
%assistance from: Eric Moyer
%2015/08/14
%% IMPORTANT
%If you use this code for analysis, please cite this source and give credit where credit is due. 
%% prepare for program 
clc
clear all
close all
warning on verbose
warning off MATLAB:colon:nonIntegerIndex
warning off curvefit:prepareFittingData:removingNaNAndInf
beep off
%% open file. If file does not exist, give error message. 
folder = input('Enter folder with .csv Files to operate on. \n  press 1 for exp5 \n  press 2 for BIS01 \n  or enter folder path name manually\n');
if  folder==1
    myFolder = 'C:\Users\MOHIT\Documents\NASA\stiffness testing\femur3pntBend\3pntCodeTest\outputData';
elseif folder==2
    myFolder = 'C:\Users\MOHIT\Documents\NASA\stiffness testing\femur3pntBend\BIS01\outputData';
else
    myFolder = folder;
end

if ~isdir(myFolder)
  errorMessage = sprintf('Error: This folder does not exist:\n%s', myFolder);
  uiwait(warndlg(errorMessage));
  return;
end

filePattern = fullfile(myFolder, '*.csv'); %registry of .csv files to operate on
csvFiles = dir(filePattern);
finalData = []; %empty array to dump values into 
row=1;
    finalData{row,1} = 'name'; %name of file/sample
    finalData{row,2} = 'stiffness'; %stiffness in linear elastic region 
    finalData{row,3} = 'disp@start of linear region'; %start range of displacement for linear region
    finalData{row,4} = 'disp@end of linear region'; %end ranage of displacement for linear region
    finalData{row,5} = 'force@yield'; %force at yield -- measured by .2% delta off span length 
    finalData{row,6} = 'disp@yield'; %displacement at yeild
    finalData{row,7} = 'strain@yield'; %strain at yield force
    finalData{row,8} = 'stress@yield'; %stress at yield force
    finalData{row,9} = 'start2yieldEnergy'; %energy absorbed from start to yield load 
    finalData{row,10} = 'force@ultimate'; %force at ultimate load 
    finalData{row,11} = 'disp@ultimate'; %displacement at ultimate load
    finalData{row,12} = 'strain@ultimate'; %strain at ultimate force
    finalData{row,13} = 'stress@ultimate'; %stress at ultimate force
    finalData{row,14} = 'start2ultimateEnergy'; %energy absorbed from start to ultimate load 
    finalData{row,15} = 'force@fracture'; %load at fracture
    finalData{row,16} = 'disp@fracture'; %displacement at fracture
    finalData{row,17} = 'strain@fracture'; %strain at fracture force
    finalData{row,18} = 'stress@fracture'; %stress at fracture force
    finalData{row,19} = 'start2FractureEnergy'; %work to fracture -- energy absorbed from start to fracture load 
    finalData{row,20} = 'postYeildDisp'; %toughness, delta in displacement from yeild to fracture
    finalData{row,21} = 'postYeildStrain'; %toughness, delta in displacement from yeild to fracture
    finalData{row,22} = 'toughness'; %area under stress strain curve 
row=2;
    finalData{row,1} = ''; %name of file/sample
    finalData{row,2} = 'N/mm'; %stiffness in linear elastic region 
    finalData{row,3} = 'mm'; %start range of displacement for linear region
    finalData{row,4} = 'mm'; %end ranage of displacement for linear region
    finalData{row,5} = 'N'; %force at yield -- measured by .2% delta off span length 
    finalData{row,6} = 'mm'; %displacement at yeild
    finalData{row,7} = '-'; %strain at yield force
    finalData{row,8} = 'N/mm^2'; %stress at yield force
    finalData{row,9} = 'N*mm'; %energy absorbed from start to yield load 
    finalData{row,10} = 'N'; %force at ultimate load 
    finalData{row,11} = 'mm'; %displacement at ultimate load
    finalData{row,12} = '-'; %strain at ultimate force
    finalData{row,13} = 'N/mm^2'; %stress at ultimate force
    finalData{row,14} = 'N*mm'; %energy absorbed from start to ultimate load 
    finalData{row,15} = 'N'; %load at fracture
    finalData{row,16} = 'mm'; %displacement at fracture
    finalData{row,17} = '-'; %strain at fracture force
    finalData{row,18} = 'N/mm^2'; %stress at fracture force
    finalData{row,19} = 'N*mm'; %work to fracture -- energy absorbed from start to fracture load 
    finalData{row,20} = 'mm'; %toughness, delta in displacement from yeild to fracture
    finalData{row,21} = '-'; %toughness, delta in displacement from yeild to fracture
    finalData{row,22} = 'toughness'; %area under stress strain curve 
row=3;
for k=1:length(csvFiles) %loop through each file in output folder
    baseFileName = csvFiles(k).name; %part of file -name- that is changing
    fullFileName = fullfile(myFolder, baseFileName); %file being operated on
    [pathstr, name, ext] = fileparts(fullFileName); %split operating file name and extension  
    array=xlsread(fullFileName, 'F:G'); %Create array of AbsForce and RelDisp
    [displacement,force]=prepareCurveData(array(:, 2),array(:, 1));
    if length(displacement)~=length(force)
        disp('Error! Data is not equal in length.')
    end
    
%% Create Force (y-axis) and Disp (x-axis)chart 
    graphString=strsplit(baseFileName,{'_','\'});
    experiment=cell2mat(graphString(1)); %name of experiment 
    sample=cell2mat(graphString(2)); %name of sample
    fprintf('Now operating on %s\n', sample);%NOTE can switch to "fullFileName" to show file name instead 
    dateTime=cell2mat(graphString(3)); %date and time
    graphTitle=strcat(experiment,'-',sample);
    graphPath=fullfile(pathstr,'graphs'); %where graphs will be located
    graphSave=strcat(graphPath,'\', graphTitle);
    xlsPath=fullfile(pathstr,'finalData'); %where final data xls will be located
    
%force - displacement 
    spanLength = 5; %mm - length of bottom platens - L in transformation equations 
    %Ix=.185; %TEMP
    %radiusPeri=1.055; %TEMP
    Ix = input('input Ix, moment of intertia about x-axis\n'); %moment of intertia about x-axis 
    radiusPeri = input('input c, periostial surface radius\n')'; %radius perpendicular to neutral axis - c in transformation equations 
    strain = (12*radiusPeri*displacement)/(spanLength)^2; %array for apprarent strain transformation
    stress = force*spanLength*radiusPeri/4/Ix; %array for apprant stress transformation
    
    figure(k)
    subplot(2,1,1)
    plot(displacement,force,'k.','MarkerSize',1); %Plot raw curve of data in black

%% Ultimate Force    
    [ultimateForce,ultimateForceLoc] = max(force); %Find the maximum point on force axis and return the location of that point
    ultimateDisp = displacement(ultimateForceLoc(length(ultimateForceLoc))); % displacement at ultimate force
    ultimateStress = stress(ultimateForceLoc(length(ultimateForceLoc))); % displacement at ultimate force
    ultimateStrain = strain(ultimateForceLoc(length(ultimateForceLoc))); % displacement at ultimate force
    axis([0,max(displacement),0,ultimateForce*1.2]); %set axis range
    hold on %retain curve, axis, and labels
    xlabel('Displacement (mm)');
    ylabel('Force (N)'); 
    title(graphTitle);
    set(gca,'XMinorTick','on','YMinorTick','on'); %add minor tick marks to graph
    plot(displacement(1:ultimateForceLoc),force(1:ultimateForceLoc),'g.','MarkerSize',1); %Plot in green until ultimate force for visual purposes
    
%% Linear Region 
    fprintf('click start and end bounds of linear elastic region\n')%User selects linear range of plot for the calculation of stiffness
    [userInputX,userInputY]=ginput(2); %User clicks two points with mouse, start and end of linear region 
    linearRegion=roundn(userInputX,-2); %Round user's selection to nearest thousandth place
    if linearRegion(1)<0 %prevent negative values from being selected
        linearRegion(1)=0;
    end
    if linearRegion(2)<0 %prevent negative values from being selected
        linearRegion(2)=0;
    end
    if linearRegion(2)<linearRegion(1); %If first point selected is upper bound instead of lower bound
        adjLinearRegion=flipud(linearRegion); %Arrange matrix from smallest to largest
        linearRegion=adjLinearRegion; %Set new range of linear region
    end
    
% Line representing slope of linear region is plotted in red
    X1=find(roundn(displacement,-3)==linearRegion(1)); %Find the actual start disp value of the linear region closest to the user selected point
    X2=find(roundn(displacement,-3)==linearRegion(2)); %Find the actual end disp value of the linear region  closest to the user selected point
    fit=polyfit(displacement(X1(1):X2(1)),force(X1(1):X2(1)),1); %Fit the values of selected linear region to line
    stiffness=fit(1); %Display stiffness (slope of linear region) in MATLAB output window
    intercept=fit(2); %Save value of X-intercept
    xValues=[min(displacement):.1:max(displacement)]; %Set x-values of red line representing slope of linear region
    predictedValues=polyval(fit,xValues); %Calculate y-values of red line representing slope of linear region
    linearPlot=plot(xValues,predictedValues,'r','MarkerSize',4); %Plot line in red representing slope of linear region
    try %Prevent red line from changing axes on plot of original data
        set(linearPlot, 'YLimInclude', 'off');
    catch
        error('Undocumented feature "YLimInclude" failed.');
    end
    
%% Yield Force
    newForce=stiffness*(displacement)+intercept-stiffness*0.002*spanLength; %2 percent offset in disp for yield point **citation**
    for j=1:length(displacement); %all data points
        if displacement(j) < displacement(X2(1))
            tempDisp(j) = displacement(X2(1)); %don't include values less than userInputX(2), end of linear region 
            tempForce(j) = force(X2(1)); %don't include values less than userInputX(2), end of linear region 
        else 
            tempDisp(j) = displacement(j); %all displacements above userInputX(2), end of linear region 
            tempForce(j) = force(j);%all force above userInputX(2), end of linear region 
        j = j+1;
        end
    end
    tempDisp= transpose(tempDisp); %shift from rows to columns 
    tempForce= transpose(tempForce); %shift from rows to columns
    
    linearPlot=plot(displacement,newForce,'b','MarkerSize',4); %Plot in blue line representing slope of linear region above userInputX(2), end linear region 
    yieldForceLoc=find(roundn(tempForce,-2)==roundn(newForce,-2)); %index of yield force location 

    for n=1:length(yieldForceLoc);
        if force(yieldForceLoc(n))>ultimateForce/5;
            yieldForce=force(yieldForceLoc(length(yieldForceLoc))); %force at yield
            yieldDisp=displacement(yieldForceLoc(length(yieldForceLoc))); %disp at yield
            yieldStress=stress(yieldForceLoc(length(yieldForceLoc))); %stress at yield
            yieldStrain=strain(yieldForceLoc(length(yieldForceLoc))); %strain at yield
        break
        elseif n==length(yieldForceLoc);
            disp('Error! Possible issue: yield offset line intersects data in data gap')
            yieldForce=0;
        end
    end

%% Find Final Fracture Force Before Force Significantly Falls
    fprintf('click fracture point\n')
    [userInputFinalFractureX,userInputFinalFractureY]=ginput(1); %user input fracture location 
    finalFractureLoc=find(roundn(displacement,-3)==roundn(userInputFinalFractureX,-3)); %find fracture location  
    fractureForce=force(finalFractureLoc(1)); %force at fracture location 
    fractureDisp=displacement(finalFractureLoc(1)); %disp at fracture location
    fractureStress=stress(finalFractureLoc(1)); %stress at fracture location
    fractureStrain=strain(finalFractureLoc(1)); %strain at fracture location
   
    postYeildDisp = fractureDisp-yieldDisp; %delta in displacement from yeild to fracture
    postYeildStrain = fractureStrain-yieldStrain; %delta in strain from yeild to fracture

%%
%-----------------------------------------------ENERGY CALCULATIONS--------------------------------------------------------------------------------------------------------------
%
%% Find energy absorbed by bone from start to yield 
    yieldEnergyPlot=area(displacement(1:yieldForceLoc),force(1:yieldForceLoc)); %Plot area - start >> yield energy
    set(yieldEnergyPlot,'FaceColor',[224/255,255/255,255/255]); %set plot color to light cyan
    start2yieldEnergy=(trapz(displacement(1:yieldForceLoc),force(1:yieldForceLoc))); %Calculate energy absorbed
%% Find energy absorbed by bone from start to ultimate force 
    ultimateEnergyPlot=area(displacement(yieldForceLoc:ultimateForceLoc),force(yieldForceLoc:ultimateForceLoc)); %Plot area - yield >> ultimate energy
    set(ultimateEnergyPlot,'FaceColor',[0/255,255/255,255/255]); %set plot color to darker cyan
    start2ultimateEnergy=(trapz(displacement(1:ultimateForceLoc),force(1:ultimateForceLoc))); %Calculate energy absorbed
%% Find energy absorbed by bone from start to fracture 
    fractureEnergyPlot=area(displacement(ultimateForceLoc:finalFractureLoc),force(ultimateForceLoc:finalFractureLoc)); %Plot area - ultimate >> fracture energy
    set(fractureEnergyPlot,'FaceColor',[0/255,139/255,139/255]); %set plot color to cyan darker still 
    start2FractureEnergy=(trapz(displacement(1:finalFractureLoc),force(1:finalFractureLoc))); %Calculate energy absorbed
%% Stress, Strain & Toughness 
    hold off
    subplot(2,1,2)
    plot(strain,stress,'k.','MarkerSize',1); %Plot raw curve of data in black
    axis([0,max(strain),0,ultimateStress*1.2]); %set axis range
    xlabel('Strain (unitless)');
    ylabel('Stress (N/mm^2)'); %add labels
    title(graphTitle);
    set(gca,'XMinorTick','on','YMinorTick','on'); %add minor tick marks to graph
    hold on 
    yieldEnergyPlot=area(strain(1:yieldForceLoc),stress(1:yieldForceLoc)); %Plot area start >> yield
    set(yieldEnergyPlot,'FaceColor',[224/255,255/255,255/255]); %set plot color to light cyan
    ultimateStrainPlot=area(strain(yieldForceLoc:ultimateForceLoc),stress(yieldForceLoc:ultimateForceLoc)); %Plot area yield>>ultimate
    set(ultimateStrainPlot,'FaceColor',[0/255,255/255,255/255]); %set plot color to darker cyan
    toughnessPlot=area(strain(ultimateForceLoc:finalFractureLoc),stress(ultimateForceLoc:finalFractureLoc)); %Plot area ultimate>>fracture
    set(toughnessPlot,'FaceColor',[0/255,139/255,139/255]); %set plot color to cyan darker still 
    toughness =(trapz(strain(1:finalFractureLoc),stress(1:finalFractureLoc))); %Calculate toughness
%% write useful variables -- for reference: 
    finalData{row,1} = sample; %name of file/sample
    finalData{row,2} = stiffness; %stiffness in linear elastic region 
    finalData{row,3} = linearRegion(1); %start range of displacement for linear region
    finalData{row,4} = linearRegion(2); %end ranage of displacement for linear region
    finalData{row,5} = yieldForce; %force at yield -- measured by .2% delta off span length 
    finalData{row,6} = yieldDisp; %displacement at yeild
    finalData{row,7} = yieldStrain; %strain at yield force
    finalData{row,8} = yieldStress; %stress at yield force
    finalData{row,9} = start2yieldEnergy; %energy absorbed from start to yield load 
    finalData{row,10} = ultimateForce; %force at ultimate load 
    finalData{row,11} = ultimateDisp; %displacement at ultiamte load
    finalData{row,12} = ultimateStrain; %strain at ultimate force
    finalData{row,13} = ultimateStress; %stress at ultimate force
    finalData{row,14} = start2ultimateEnergy; %energy absorbed from start to ultimate load 
    finalData{row,15} = fractureForce; %load at fracture
    finalData{row,16} = fractureDisp; %displacement at fracture
    finalData{row,17} = fractureStrain; %strain at fracture force
    finalData{row,18} = fractureStress; %stress at fracture force
    finalData{row,19} = start2FractureEnergy; %work to fracture -- energy absorbed from start to fracture load 
    finalData{row,20} = postYeildDisp; %toughness, delta in displacement from yeild to fracture
    finalData{row,21} = postYeildStrain; %toughness, delta in displacement from yeild to fracture
    finalData{row,22} = toughness; %area under stress strain curve 
%% Save raw data to excel and image file as .jpeg 
saveas(gcf, graphSave,'jpeg');%gcf=currentFigureHandle
points=transpose(1:length(force)); %max index for area of analysis
rawData=horzcat(points, force, displacement, stress, strain);
rawDataSave=strcat(experiment, '_', sample,'_', 'rawData');
xlsRawData=fullfile(pathstr,rawDataSave); %where raw data xls will be located
xlswrite(xlsRawData, rawData)
row=row+1;
end
xlswrite(xlsPath, finalData)
fprintf ('finished! \nhave an excellent day! \n')
