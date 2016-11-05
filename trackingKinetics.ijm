macro "Main" {
	tableFileExtension = ".csv";
	//tableFileExtension = ".txt";
	Messages = "";
	nFDh = 800;
	nFDv = round(nFDh*0.40);

	Delta = fromCharCode(0x0394);
	PlusMinus=fromCharCode(0xB1);
	Space=fromCharCode(0x20);
	DQ=fromCharCode(0x22);
	LF=fromCharCode(0x0A);
	CR=fromCharCode(0x0D);
	Enter = CR+LF;

	//run("Monitor Memory...");wait(500);

  	setBatchMode(false);

	closeFlag = true;
	Initialize(closeFlag);
	mainLoopFlag = true;
	while (mainLoopFlag) {
		if (isOpen("Flow Diagram")) {
			close("Flow Diagram");
			wait(1);
		}
		newImage("Flow Diagram", "8-bit white", nFDh, nFDv, 1);
		//call("ij.gui.ImageWindow.setNextLocation", x, y);
		a = newArray("gray","gray","gray","gray","gray","gray");
		locationMainBoxes = Update_FD(a);
		Index = Get_Mouse_Polling(locationMainBoxes);
		selectWindow("Flow Diagram");
		if (Index == 5) {
			a = newArray("white","white","white","white","white","white");
			locationMainBoxes = Update_FD(a);
			if (roiManager("count") > 0) {
				roiManager("Deselect");
				roiManager("Delete");
			}
			selectWindow("Flow Diagram");
			wait(1);
			close("Flow Diagram");
			wait(1);
			mainLoopFlag = false;
		} else {
			a = newArray("gray","gray","gray","gray","gray","gray");
			a[Index] = "Blue";
			locationMainBoxes = Update_FD(a);
			wait(200);
			close("Flow Diagram");
			wait(1);
			if (Index == 0) {
				dummy_1 = Run_Processing();
			} else if (Index == 1) {
				dummy_1 = Run_Tracking();
				mainLoopFlag = false;
			} else if (Index == 2) {
				dummy_1 = Run_ROI_Definition();
			} else if (Index == 3) {
				dummy_1 = Run_Measurement();
			} else if (Index == 4) {
				dummy_1 = Run_Visualization();
				//mainLoopFlag = false;
			}
			if (dummy_1 == -1) {
				mainLoopFlag = false;
			}
		}
	}
}

function Initialize_ROI_Overlay() {
	run("ROI Manager...");
	roiManager("Show All without labels");
  	roiManager("reset");
  	if (roiManager("count") > 0)	{
	 roiManager("Deselect");
	 roiManager("Delete");
	}
	Overlay.remove();
	Overlay.show();
	run("Select None");
	//run("Monitor Memory...");
}

function Initialize(closeFlag) {
	if (closeFlag) {
		run("Close All");
		wait(100);
	}
	//run("Record...");
	
  	roiManager("reset");
  	if (roiManager("count") > 0)	{
	 roiManager("Deselect");
	 roiManager("Delete");
	}
	
	if (isOpen("ROI Manager")) {
	 selectWindow("ROI Manager");
	 run("Close"); 
	}
	
	run("Clear Results");
	updateResults();
	if (isOpen("Results")) {
	 selectWindow("Results");
	} else {
	 run("Results");
	}
	print("\\Clear");
	//run("Collect Garbage");wait(10);
}

function findTrackCenters(x,y,nTrackArray) {
	trackCenters=newArray(2*nTracks);
	totalIndex=0;
	for (i = 0; i < nTracks; i++) {
		//print("nTracks = "+nTracks+", n_nTrackArray = "+lengthOf(nTrackArray)+", i = "+i);
		//print("totalIndex = "+totalIndex+", nTrackArray[i] = "+nTrackArray[i]);
		X_=Array.slice(x,totalIndex,totalIndex+nTrackArray[i]);
		Array.getStatistics(X_, dummy_1, dummy_2, xMean, dummy3);
		Y_=Array.slice(y,totalIndex,totalIndex+nTrackArray[i]);
		Array.getStatistics(Y_, dummy_1, dummy_2, yMean, dummy3);
		trackCenters[2*i]=xMean;
		trackCenters[2*i+1]=yMean+12;
		totalIndex=totalIndex+nTrackArray[i];
	}
	//Array.print(trackCenters);waitForUser("Holla!");
	return trackCenters;
}

function Select_Track(nTracks) {
	Tracks=newArray(nTracks);
	for (i=0; i<nTracks; i++) {
		Tracks[i]=(i+1);
	}
	Continue = true;
	while (Continue) {
		Dialog.create("Track to be analyzed");
		Dialog.addNumber("Initial Time", 1);
		Dialog.addNumber("Final Time", nTime);
		Dialog.addChoice("Track:", Tracks);
		Dialog.show(); 
		tIni = Dialog.getNumber();
		tFin = Dialog.getNumber();
		visibleTrack = parseInt(Dialog.getChoice());
		if (tFin < tIni) {
			waitForUser("Time Sequence Correction","Initial Time ("+tIni+") and Final Time ("+tFin+") are swapped.");
			wait(1);
			dummy_1 = tFin;
			tFin = tIni;
			tIni = dummy_1;
		}
		if (tIni < MinMaxTracksArray[2*(visibleTrack - 1)]) {
			tIni = MinMaxTracksArray[2*(visibleTrack - 1)];
			waitForUser("Initial Time Correction","Initial Time set to "+tIni+" (earliest for Track #"+visibleTrack+").");
			wait(1);
		}
		if (tFin > MinMaxTracksArray[2*(visibleTrack - 1)+1]) {
			tFin = MinMaxTracksArray[2*(visibleTrack - 1)+1];
			waitForUser("Final Time Correction","Final Time set to "+tFin+" (latest for Track #"+visibleTrack+").");
			wait(1);
		}
		if (tFin < tIni) {
			print("Min = "+MinMaxTracksArray[2*(visibleTrack - 1)+0]+", Max = "+MinMaxTracksArray[2*(visibleTrack - 1)+1]+", N = "+nTrackArray[visibleTrack - 1]);
			Array.print(MinMaxTracksArray);
			Array.print(nTrackArray);
			waitForUser("No track points in this time interval.","Please select a different time interval and/or track.");
			wait(1);
		} else {
			Continue = false;
		}
	}
	varArgOut=newArray(3);
	varArgOut[0]=visibleTrack;
	varArgOut[1]=tIni;
	varArgOut[2]=tFin;
	return varArgOut;
}

function Traverse_All_Track_Points(x,y,t,trackNormalIndices,trackCenters,nTrackArray,selectTrackTime,trnsprncGrdnt) {
	visibleTrack=selectTrackTime[0];
	tMin=selectTrackTime[1];
	tMax=selectTrackTime[2];
	//Loading tracks (from RESULTS) and defining corresponding (circular) OVERLAYs
	Array.getStatistics(t, dummy1, tMax, dummy2, dummy3);
	//print(tMax);waitForUser("blah");
	run("Remove Overlay");
	run("Show Overlay");
	run("Select None");
	wait(20);
	nColor=round(sqrt(nTracks+1))+2;
	//print(nColor);wait(2000);
	//Overlay.drawString("1",trackCenters[0],trackCenters[1]);
	colorMargin=0.20;
	Show_All_Tracks=0;
	colorIndex=0;
	indTrackCntr=1;
	for (i = 0; i < nTotal; i++) {
		 //print("i = "+i+", nTotal = "+nTotal+", size(t) = "+lengthOf(t));
	     if ((visibleTrack == trackNormalIndices[i]) || (visibleTrack <= 0)) {
		     if (visibleTrack < 0) {
		     	xDiameter = floor(2 * (- visibleTrack) / Decimation);
		     	yDiameter = floor(2 * (- visibleTrack) / Decimation);
		     } else {
			     xDiameter=floor(20/Decimation);
			     yDiameter=floor(20/Decimation);
		     }
		     xCenter=x[i]-xDiameter/2;
		     yCenter=y[i]-yDiameter/2;
		     if ((xCenter > 0) & (yCenter > 0)) {
		     } else {
			     print("Image border hit by track at (x,y)=("+x[i]+","+y[i]+")");
		     }
			 //setSlice(1+t[i]);
			 setSlice(1);
		     makeOval(xCenter, yCenter, xDiameter, yDiameter);
		     Color=(colorIndex/nTracks)*0x0000ff+0.1*0x00ff00+(1-colorIndex/nTracks)*0xff0000;
		     Transparency=round(0xff*(1-trnsprncGrdnt*t[i]/(tMax*(1+colorMargin))));
		     Overlay.addSelection("",0,"#"+toHex(Transparency)+toHex(Color));
		     //Overlay.addSelection("#"+toHex(Transparency)+toHex(Color));
		     Overlay.setPosition(1,1,1+t[i]);
		     if ((indTrackCntr == nTrackArray[colorIndex]) & (visibleTrack < 0)) {
				indTrackCntr=1;
				Overlay.drawString(colorIndex+1,trackCenters[2*colorIndex],trackCenters[2*colorIndex+1])
				setFont("SansSerif", 20, " antialiased");
				setColor("white");
				run("Select None");roiManager("Deselect");
				Overlay.show();
				colorIndex=colorIndex+1;
		     	if (colorIndex < nTracks) {
		     		if (Show_All_Tracks == 0) {
			     		Dialog.create("Track #"+(colorIndex+1));
			  			Dialog.addCheckbox("Show All Tracks", true);
	  					Dialog.show();
						Show_All_Tracks = Dialog.getCheckbox();
		     		}
		     	} else {
		     		//Dialog.create("Remove Overlay Indices");Dialog.show();
		     	}
		     } else {
				indTrackCntr=indTrackCntr+1;
		     }
	     }
	}
	run("Select None");
	wait(1);
}

function Define_ROI(selectTrackTime) {
	Delay_0 = 40;
	Delay = 50;
	visibleTrack=selectTrackTime[0];
	tIni=selectTrackTime[1];
	tFin=selectTrackTime[2];
	Array.getStatistics(t, dummy1, tMax, dummy2, dummy3);

	//Define all intended track points as new overlays
	run("Remove Overlay");
	Overlay.show();
	run("Select None");

	xDiameter = floor(20/Decimation);
	yDiameter = floor(20/Decimation);

	transparencyGradient = 0;
	Dialog.create("ROI Parameters");
	Dialog.addNumber("Diameter (Horizontal)", xDiameter);
	Dialog.addNumber("Diameter (Vertical)", yDiameter);
	Dialog.show(); 
	xDiameter = Dialog.getNumber();
	yDiameter = Dialog.getNumber();
	includeAllPoints = 0;
	colorMargin=0.20;
	colorIndex=visibleTrack;
	for (i = 0; i < nTotal; i++) {
	    if ((visibleTrack == trackNormalIndices[i])) {
		    if ((t[i] >= (tIni - 1)) & (t[i] <= (tFin - 1))) {
			     xCenter=x[i]-xDiameter/2;
			     yCenter=y[i]-yDiameter/2;
				 setSlice(1+t[i]);
			     makeOval(xCenter, yCenter, xDiameter, yDiameter);
			     Color=(colorIndex/nTracks)*0x0000ff+0.1*0x00ff00+(1-colorIndex/nTracks)*0xff0000;
			     Transparency=round(0xff*(1-tMax/(tMax*(1+colorMargin))));
			     //Overlay.addSelection("",0,"#"+toHex(Transparency)+toHex(Color));
			     Overlay.addSelection("#"+toHex(Transparency)+toHex(Color));
			     Overlay.setPosition(1,1,1+t[i]);
		    }
		}
	}
	run("Select None");
	wait(1);

	//Clearing ROI Manager
	run("ROI Manager...");
	roiManager("Show All without labels");
  	roiManager("reset");
  	if (roiManager("count") > 0)	{
	 roiManager("Deselect");
	 roiManager("Delete");
	}
	wait(1);

	//Transfer the new overlays to ROI manager, select none
	run("To ROI Manager");
	roiManager("Show All without labels");
	roiManager("Deselect");
	run("Hide Overlay");
	waitForUser(roiManager("count")+" (unselected) ROIs");
	wait(10);

	//Finding the global indices of the first intended track point
	//print("\\Clear");
	Base=0;
	if (visibleTrack > 1) {
		for (cntr=0; cntr <(visibleTrack-1); cntr++) {
			Base=Base+nTrackArray[cntr];
		}
	}
	//print("Base at the end of the FIRST loop = "+Base);
	while(t[Base] < (tIni-1)) {
		Base=Base+1;
	}
	//print("Base at the end of the SECOND loop = "+Base);
	nSelectTrack=0;
	while(t[Base+nSelectTrack] < (tFin-1)) {
		nSelectTrack=nSelectTrack+1;
	}
	nSelectTrack=nSelectTrack+1;
	print("Base = "+Base+", nSelectTrack = "+nSelectTrack);

	//In a loop, ask for trimming ROI and do a measurement
	waitForUser("Loading ROIs in the Results Table");
	run("Clear Results");
	updateResults();
	selectWindow("Results");
	wait(100);
	

	Dialog.create("Delay setting");
	Dialog.addNumber("Delay", Delay);
	Dialog.show(); 
	Delay = parseInt(Dialog.getNumber());
	wait(1);
	
	xOval = newArray(nSelectTrack);
	yOval = newArray(nSelectTrack);
	xDOval = newArray(nSelectTrack);
	yDOval = newArray(nSelectTrack);
	Time = newArray(nSelectTrack);
	v = newArray(nSelectTrack);
	gIndex = newArray(nSelectTrack);
	Cntr = 0;
	includeStatus = includeAllPoints;
	run("Set Measurements...", "redirect=None decimal=1");
	for (cntr = 0; cntr < nSelectTrack; cntr++) {
		if (includeStatus > -1) {
			//roiManager("Deselect");
			roiManager("Select", cntr);
			wait(10);
			//print("cntr = "+cntr+", Base = "+Base+", Base + cntr = "+(Base + cntr));
			setSlice(1+t[Base+cntr]);
		}
		if (includeStatus == 0) {
			Dialog.create("Current Point");
			Dialog.addChoice("Action", newArray("Include (Current and) Rest","Exclude (Current and) Rest","Include","Exclude"));
			Dialog.show(); 
			dummy_1 = Dialog.getChoice();
			if (dummy_1 == "Include") {
				includeStatus = 1;
			} else if (dummy_1 == "Include (Current and) Rest") {
				includeStatus = 2;
				includeAllPoints = 1;
			} else if (dummy_1 == "Exclude (Current and) Rest") {
				includeStatus = -1;
			}
		}
		if (includeStatus > 0) {
			Time[Cntr]= 1 + t[Base+cntr];
			xDOval[Cntr]= xDiameter;
			yDOval[Cntr]= yDiameter;
			xOval[Cntr]= x[Base+cntr]-xDOval[Cntr]/2;
			yOval[Cntr]= y[Base+cntr]-yDOval[Cntr]/2;
			gIndex[Cntr]= Base+cntr;
			setResult("Time", Cntr, Time[Cntr]);
			setResult("Oval_ROI_X", Cntr, xOval[Cntr]);
			setResult("Oval_ROI_Y", Cntr, yOval[Cntr]);
			setResult("Global_Track_Index", Cntr, gIndex[Cntr]);
			setResult("Oval_ROI_dX", Cntr, xDOval[Cntr]);
			setResult("Oval_ROI_dY", Cntr, yDOval[Cntr]);
			setResult("Track Index", Cntr, visibleTrack);
			setResult("Measurement", Cntr, NaN);
			updateResults();
			print("Cntr = "+Cntr+", xDOval[Cntr] = "+xDOval[Cntr]+", xOval[Cntr] = "+xOval[Cntr]+", xDiameter = "+xDiameter);
			Cntr = Cntr + 1;
			wait(Delay);
		}
		if (includeStatus > -1) {
			includeStatus = includeAllPoints;
		}
	}
	Time=Array.slice(Time,0,Cntr);
	xOval=Array.slice(xOval,0,Cntr);
	yOval=Array.slice(yOval,0,Cntr);
	xDOval=Array.slice(xDOval,0,Cntr);
	yDOval=Array.slice(yDOval,0,Cntr);
	gIndex=Array.slice(gIndex,0,Cntr);

	print("nResults = "+nResults);
	
	run("Select None");
	selectWindow("Results");
	wait(1);
	run("Input/Output...", "jpeg=85 gif=-1 file="+tableFileExtension+" copy_column save_column");
	waitForUser("Please save ROIs");
	//IJ.renameResults("ROIs");
	//selectWindow("ROIs");
	saveAs("results");
	wait(10);

	Dialog.create("Correlation Analysis of track #"+visibleTrack);
	Dialog.addCheckbox("Plotting \"Mean Square Distance\" vs. \"Time Lag\"?", true);
	Dialog.addHelp("http://www.nature.com/mt/journal/v19/n7/fig_tab/mt2011102f2.html#figure-title");
	Dialog.show();
	if (parseInt(Dialog.getCheckbox()) == true) {
		Correlation_Analysis(xOval, yOval, Time);
	}
	wait(1);
}

function Load_Tracks_in_Results_Table() {
	run("Set Measurements...", "redirect=None decimal=1");
	run("Clear Results");
	updateResults();
	selectWindow("Results");
	for (cntr = 0; cntr < N; cntr++) {
		setResult("Track", cntr, trackNormalIndices[cntr]);
		setResult("Time", cntr, t[cntr]);
		setResult("x", cntr, x[cntr]);
		setResult("y", cntr, y[cntr]);
	}
	updateResults();
	print("nResults = "+nResults);
	selectWindow("Results");
}

function Find_nData(StringXML) {
	N = 0;
	Continue = true;
	while (Continue == true) {
		dummy_1 = indexOf(StringXML,"<detection");
		if (dummy_1 != -1) {
			N = N +1;
			StringXML = substring(StringXML,1 + dummy_1);
		} else {
			Continue = false;
		}
	}
	return N;
}

function Find_nTracks(StringXML) {
	StringXML = substring(StringXML,indexOf(StringXML,">"));	//From the end of the first line
	StringXML = substring(StringXML,1+indexOf(StringXML,DQ)); //From the first character (last digit) of nTracks
	nTracks = substring(StringXML,0,indexOf(StringXML,DQ));
	return nTracks;
}

function Load_x_y_t_Track_nTA_mMTA_tNI(XMLString,N) {
	trackNormalIndices = newArray(N);
	Track = newArray(N);
	t = newArray(N);
	x = newArray(N);
	y = newArray(N);

	a = XMLString;
	a = substring(a,indexOf(a,">"));	//From the end of the first line
	a = substring(a,1+indexOf(a,DQ)); //From the first character (last digit) of nTracks
	nTracks = substring(a,0,indexOf(a,DQ));
	nTrackArray = newArray(nTracks);
	MinMaxTracksArray = newArray(2*nTracks);
	
	nPoints = 0;
	for (cntr = 0; cntr < nTracks; cntr++) {
		a = substring(a,8+indexOf(a,"nSpots"));	//"particle ID" line
		particleID = parseInt(substring(a,0,indexOf(a,DQ)));
		nTrackArray[cntr] = 0;
		Continue = true;
		firstTimeFlag = true;
		while (Continue == true) {
			a = substring(a,3+indexOf(a,"t="));
			t[nPoints] = parseInt(substring(a,0,indexOf(a,DQ)));
			a = substring(a,3+indexOf(a,"x="));
			x[nPoints] = parseInt(substring(a,0,indexOf(a,DQ)));
			a = substring(a,3+indexOf(a,"y="));
			y[nPoints] = parseInt(substring(a,0,indexOf(a,DQ)));

			Track[nPoints] = particleID;
			trackNormalIndices[nPoints] = cntr + 1;
			nTrackArray[cntr] = nTrackArray[cntr] + 1;
			if (firstTimeFlag == true) {
				MinMaxTracksArray[2*cntr] = t[nPoints] + 1;
				firstTimeFlag = false;
			}

			print("nPoints = "+nPoints+", Track = "+Track[nPoints]+", Time = "+t[nPoints]+", x = "+x[nPoints]+", y = "+y[nPoints]);
			nPoints = nPoints +1;
			Limit = indexOf(a,"</particle");
			dummy_1 = 3+indexOf(a,"t=");
			if ( (dummy_1 > Limit) | (dummy_1 == -1) | (nPoints == N)) {
				Continue = false;
				MinMaxTracksArray[2*cntr + 1] = t[nPoints - 1] + 1;
			}
		}
	}
	dummy_1 = Array.concat(x,y);
	dummy_1 = Array.concat(dummy_1,t);
	dummy_1 = Array.concat(dummy_1,Track);
	dummy_1 = Array.concat(dummy_1,nTrackArray);
	dummy_1 = Array.concat(dummy_1,MinMaxTracksArray);
	dummy_1 = Array.concat(dummy_1,trackNormalIndices);
	return dummy_1;
}

function Add_Text(Text,xText,yText,fontSize,fontColor) {
	setFont("SansSerif", fontSize, " antialiased");
	setColor(fontColor);
	Overlay.drawString(Text, xText, yText, 0.0);
}

function Place_Arrow(X1,Y1,X2,Y2) {
	makeArrow(X1,Y1,X2,Y2,"filled small");
	Roi.setStrokeWidth(3);
	Roi.setStrokeColor("red");
	run("Add Selection...");
}

function Update_FD(fontColors) {
	N = lengthOf(fontColors);
	xOffset = 0.01 * nFDh;
	xStep = 0.185 * nFDh;
	xArrowGap = 0.005 * nFDh;
	xArrowLength = 0.04 * nFDh;
	//dummy_1 = "Measurement"+fromCharCode(0x222C);
	Label = newArray(" Processing","   Tracking","ROI Definition", " Measurement"," Visualization"," End");
	X = newArray(N);
	Y = round(nFDv*0.45);
	for (cntr = 0; cntr < N; cntr++) {
		X [cntr] = round(xOffset + cntr * xStep);
		Add_Text(Label[cntr], X [cntr], Y, 18, fontColors[cntr]);
		Overlay.show();
		if (cntr > 0) {
			Place_Arrow(X[cntr] - xArrowLength, round(Y*0.93), X[cntr] - xArrowGap, round(Y*0.93));
			Overlay.show();
		}
	}
	setTool("line");
	setTool("rectangle");
	return X;
}

function Get_Mouse_Polling(X) {
	shift=1;
    ctrl=2; 
    rightButton=4;
    alt=8;
    leftButton=16;
    insideROI = 32; // requires 1.42i or later

	descriptionText = newArray(6);
	descriptionText[0] = "Image source specification"+Enter+"Contrast enhancement"+Enter+"Channel / Slice selection"+Enter+"Size calibration elimination"+Enter+"Median filtering"+Enter+"Conversion to 8-bit"+Enter+"downscaling ('Binning')"+Enter+"Thresholding"+Enter+"Binarizing"+Enter+"Saving";
	descriptionText[1] = "Image source specification"+Enter+"Channel and Slice selection"+Enter+"Size calibration elimination"+Enter+"Spot detection"+Enter+"Thresholding"+Enter+"View Selection"+Enter+"Filtering"+Enter+"Tracking"+Enter+"Saving";
	descriptionText[2] = "Track source specification"+Enter+"Loading Tracks"+Enter+"Image source specification"+Enter+"Channel and Slice selection"+Enter+"Displaying overlaid tracks"+Enter+"Selecting a track"+Enter+"Defining ROIs on selected track"+Enter+"Saving";
	descriptionText[3] = "Image source specification"+Enter+"Channel and Slice selection"+Enter+"ROI source specification"+Enter+"Loading ROIs"+Enter+"Measurement"+Enter+"Saving";
	descriptionText[4] = "Measurement source specification"+Enter+"Loading Measurements"+Enter+"Plot type I"+Enter+"Plot type II";
	descriptionText[5] = "End";

    X_ = X;
    Offset = round(0.5*(X[1]-X[0]));
    for (cntr = 0; cntr < lengthOf(X); cntr++) {
    	X_[cntr] = X_[cntr] + Offset;
    }
	run("To ROI Manager");
	roiManager("Show All without labels");
	x2 = -1; y2 = -1; lastBoxIndex = -1;
	if (getVersion>="1.37r") {
	  setOption("DisablePopupMenu", true);
	}
	Continue = true;
	while (Continue) {
		getCursorLoc(xMouse, yMouse, zMouse, flagsMouse);
		if ((flagsMouse & leftButton) != 0) {
			Continue = false;
			closestIndex = Closest_to_Main_Boxes(X_,xMouse,yMouse);
		} else if ((x2 != xMouse) & (y2 != yMouse) & (xMouse > 1) & (xMouse < (X[5]+30))){
			x2 = xMouse;
			y2 = yMouse;
			boxIndex = 1 + floor((xMouse - X[0]) / (X[1] - X[0]));
			//print("boxIndex ="+boxIndex);
			if (boxIndex != lastBoxIndex) {
				lastBoxIndex = boxIndex;
				if (roiManager("count") > 11) {
					//waitForUser("n(ROI) = "+roiManager("count"));
					selectWindow("Flow Diagram");
					wait(20);
					roiManager("select",roiManager("count") - 1);
					roiManager("Delete");
					roiManager("Show All without labels");
					selectWindow("Flow Diagram");
					wait(20);
					//waitForUser("n(ROI) = "+roiManager("count"));
				}
				selectWindow("Flow Diagram");
				run("From ROI Manager");
				Add_Text(descriptionText[boxIndex],X[boxIndex] - Offset,160,10,"black");
				Overlay.show();
				//waitForUser("Before");
				run("To ROI Manager");
				//waitForUser("After");
				roiManager("Show All without labels");
				selectWindow("Flow Diagram");
				wait(20);
			}
		}
	}
	wait(10);
	if (getVersion>="1.37r") {
		setOption("DisablePopupMenu", false);
	}
	wait(10);
	roiManager("select",roiManager("count") - 1);
	roiManager("Delete");
	roiManager("Show All without labels");
	wait(10);
	return closestIndex;
}

function Closest_to_Main_Boxes(X,xMouse,yMouse) {
    nX = lengthOf(X);
    Distance = newArray(nX);
    sortedDistance = newArray(nX);
    for (cntr = 0; cntr < nX; cntr++) {
		Distance[cntr] = abs(X[cntr]-xMouse);
		sortedDistance[cntr] = Distance[cntr];
    }
    Array.sort(sortedDistance);
    closestIndex = 0;
    cntr = 0;
    Continue = true;
    while (Continue) {
		if (Distance[cntr] == sortedDistance[0]) {
			closestIndex = cntr;
			Continue = false;
		}
		cntr = cntr + 1;
		if (cntr == nX) {
			Continue = false;
		}
    }
	return closestIndex;
}

function Run_Processing() {
	Decimation = 2;
	Delay = 1500;
	Cases = newArray("Hyperstack","Two Folders ("+DQ+"sorted"+DQ+" files)","Raw data");

	continueFlag = true;
	while (continueFlag == true) {
		fileInfo = "";
		Dialog.create("Source of Images");
		Dialog.addChoice("Image Sequence "+fileInfo+"is to be imported from", Cases);
		Dialog.show();
		selectedCase = Dialog.getChoice();
		continueFlag = false;
		if (selectedCase == Cases[0]) {
		} else if (selectedCase == Cases[1]) {
			dummy_1 = Form_Save_Load_Hyperstack();
			if (dummy_1 != 0) {
				continueFlag = true;
			}
		} else if (selectedCase == Cases[2]) {
			waitForUser("Handling raw data is not possible yet. Please try later.");
				continueFlag = true;
		}
		wait(1);
	}
	
	fileInfo = "(for Tracking) ";
	newImageFileFull = Load_UseOpen_Image(fileInfo);
	pathName = File.directory;
	fileName = File.nameWithoutExtension;
	if (getInfo("window.type") != "Image") {
		print("Non-image window ("+getInfo("window.type")+") used as image source.");
		return -1;
	} else {
		if (endsWith(getTitle(),"tiff")) {
			Extension = ".tiff";
		} else {
			Extension = ".tif";
		}
		setSlice(1);setColor(0xff, 0x99, 0x0);setFont("Serif", 28, "antialiased");

		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
		Dialog.create("Resizing");
		Dialog.addNumber("Reduction Factor",Decimation);
		Dialog.show();
		Decimation = parseInt(Dialog.getNumber());
		if (Decimation > 1) {
			imageTitles = getList("image.titles");
			doWithAnnouncement("Downscaling ("+Decimation+"x"+Decimation+" --> 1x1) ...",350,500,"DLE08Scale...x=- y=- z=1.0 width="+(imageWidth/Decimation)+" height="+(imageHeight/Decimation)+" depth="+(imageFrames*imageSlices)+" interpolation=Bilinear average process create title=["+imageTitles[0]+"]",Delay);
			wait(10);
			imageTitles_ = getList("image.titles");
			while (lengthOf(imageTitles_) < 2) {
				imageTitles_ = getList("image.titles");
			}
			Array.print(imageTitles_);
			imageWidth = newArray(2);
			for (cntr = 0; cntr < 2; cntr ++) {
				selectWindow(imageTitles_[cntr]);
				wait(100);
				getDimensions(imageWidth[cntr], imageHeight, imageChannels, imageSlices, imageFrames);
			}
			if (imageWidth[0] > imageWidth[1]) {
				Cntr = 1;
			} else {
				Cntr = 0;
			}
			wait(100);
			selectWindow(imageTitles_[1 - Cntr]);
			wait(100);
			close();
			wait(100);
			selectWindow(imageTitles_[Cntr]);
			wait(10);
			saveAs("tiff");
			wait(100);
			//run("Set... ", "zoom="+(Decimation*100)+" x=64 y=64");
			setFont("Serif", floor(56/Decimation), "antialiased");
		}
		
		doWithAnnouncement("Enhancing Contrast ...",80,250,"DLE16Enhance Contrastsaturated=0.35",Delay);
		imageTitle = Return_Single_Channel(Messages,newImageFileFull);
		//doWithAnnouncement("Enhancing Contrast ...",150,250,"DLE16Enhance Contrastsaturated=0.35",Delay);
		doWithAnnouncement("Median Filtering ...",80,250,"DLE09Median...radius=6 stack",Delay);
		doWithAnnouncement("Conversion to 8-Bit ...",80,250,"8-bit",Delay);
		
		Overlay.drawString("Thresholding ...",floor(0.156*imageHeight/Decimation),floor(0.488*imageHeight/Decimation));Overlay.show();wait(Delay);
		setThreshold(33, 255);
		Overlay.remove();Overlay.show();
		doWithAnnouncement("Binarizing ...",floor(0.156*imageHeight/Decimation),floor(0.488*imageHeight/Decimation),"DLE11Make Binarymethod=Default background=Dark calculate black",Delay);
		//doWithAnnouncement("Filling corrugated edges ...",5,64,"Close-",Delay);

		Dialog.create("How to continue?");
		Dialog.addCheckbox("Applying Watershed",true);
		Dialog.show();
		if (Dialog.getCheckbox() == true) {
			//doWithAnnouncement("Inverting LUT ...",floor(0.156*imageHeight/Decimation),floor(0.488*imageHeight/Decimation),"Invert LUT",Delay);
			doWithAnnouncement("Watershedding ...",floor(0.156*imageHeight/Decimation),floor(0.488*imageHeight/Decimation),"DLE09Watershedstack",Delay);
			//doWithAnnouncement("Inverting LUT ...",floor(0.156*imageHeight/Decimation),floor(0.488*imageHeight/Decimation),"Invert LUT",Delay);
		}
		wait(1);
		saveAs("tiff");

		//doWithAnnouncement("Saving ...",floor(150/Decimation),floor(250/Decimation),"DLE04Savesave=["+pathName+"C"+sCh+"-"+fileName+"-1.tif]",Delay);
		wait(100);
		//doWithAnnouncement("Monitoring Memory ...",floor(100/Decimation),floor(250/Decimation),"Monitor Memory...",Delay);
		return 0;
	}
}

function Run_Tracking() {
	Decimation = 1;
	Delay = 500;
	fileInfo = "(FIRST channel with pre-processing) ";
	newImageFileFull = Load_UseOpen_Image(fileInfo);

	Dialog.create("Tracking Method");
	Dialog.addChoice("Tracking Method:", newArray("Manual","TrackMate"));
	Dialog.show();
  	if (Dialog.getChoice() == "TrackMate") {
		imageTitle = Return_Single_Channel(Messages,newImageFileFull);
		if (lengthOf(imageTitle) == 2) {
			selectWindow(imageTitle[0]);
			wait(10);
		}
		doWithAnnouncement("Running TrackMate ...",floor(100/Decimation),floor(250/Decimation),"TrackMate",Delay);
  	} else {
		Messages = "Auxiliary";
		LoopFlag = true;
	 	while (LoopFlag == true) {
			imageTitle = Return_Single_Channel(Messages,newImageFileFull);
			if (lengthOf(imageTitle) == 2) {
				imageAuxTitle = imageTitle[1];
				imageTitle = imageTitle[0];
				print("A MAIN- and an AUXILIARY-image are used for tracking.");
			} else {
				imageAuxTitle = "-1";
				print("A single image is used for tracking.");
			}
			//waitForUser("In the following window: Synchronize All and then Close");
			//wait(1);
			if (imageAuxTitle != "-1") {
				run("Synchronize Windows");
				while (getInfo("window.type") != "SyncWindows") {
				}
				waitForUser("Synchronize All; then continue");
				wait(20);
				selectWindow(imageAuxTitle);
				wait(20);
				//getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
				//run("Properties...", "channels="+imageChannels+" slices="+imageFrames+" frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
				doWithAnnouncement("Enhancing Contrast ...",100,250,"DLE16Enhance Contrastsaturated=0",Delay);
				wait(1);
			}
			selectWindow(imageTitle);
			//getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
			//run("Properties...", "channels="+imageChannels+" slices="+imageFrames+" frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
			wait(20);
  			Manual_Tracking(imageTitle);
			LoopFlag = getBoolean("Define a new ROI set?");
			if (LoopFlag == true) {
				run("Close All");
				while (nImages > 0) {
				}
				wait(1);
				open(newImageFileFull);
				wait(1);
			}
	 	}
  	}
	return 1;
}

function Run_ROI_Definition() {
	//Parameters to be set by user
	// Please edit!
	Decimation = 1;
	trnsprncGrdnt = 1;
	Delay = 1000;
	// Please do NOT edit anymore!

	//Initialization
	closeFlag = false;
	Initialize(closeFlag);


	//Loading the tracks info (directly from XML file)
	a = File.openAsString(File.openDialog("Select the Tracks (XML) file"));
	nTracks = Find_nTracks(a);
	N = Find_nData(a);
	concatData = Load_x_y_t_Track_nTA_mMTA_tNI(a,N);
	x = Array.slice(concatData,0*N,1*N);
	y = Array.slice(concatData,1*N,2*N);
	t = Array.slice(concatData,2*N,3*N);
	Track = Array.slice(concatData,3*N,4*N);
	nTrackArray = Array.slice(concatData,4*N,4*N+nTracks);
	MinMaxTracksArray = Array.slice(concatData,4*N+nTracks,4*N+3*nTracks);
	trackNormalIndices = Array.slice(concatData,4*N+3*nTracks,5*N+3*nTracks);
	trackCenters=findTrackCenters(x,y,nTrackArray);

	//Loading the image to be used for DEFINING ROIs
	newImageFileFull = File.openDialog("Select the Image for defining ROI's (FIRST channel)");
	open(newImageFileFull);
	doWithAnnouncement("Enhancing Contrast ...",100,250,"DLE16Enhance Contrastsaturated=0",Delay);

	imageTitle = Return_Single_Channel(Messages,newImageFileFull);
	doWithAnnouncement("LUT Change to Gray...",100,250,"Grays",Delay);

	if (Decimation > 1) {
		run("Set... ", "zoom="+(floor(100*Decimation)));
	}

	nTime=nSlices();
	valueMax=255;
  	//setBatchMode(false);

  	continueFlag = true;
  	while (continueFlag == true) {
		//Loading the tracks info into the Results Table and analyzing them
	  	waitForUser("Start of loop: Loading Tracks into the Results Table");
		wait(1);
		Load_Tracks_in_Results_Table();
		nTotal=nResults();	// Total number of track records
		//print("N(trackCenters) = "+lengthOf(trackCenters)+", = "++", = "++", = "++", = "++", = "++", = "++", = "++", = ");
		waitForUser("Please verify the Track information");
		wait(1);

	  	//Clearing ROI Manager and removing Overlays
	  	waitForUser("Initializing ROI and Overlay");
		wait(1);
	  	Initialize_ROI_Overlay();
	
		// Select the new image window
		selectWindow(imageTitle);
		wait(10);
	
		//Showing all tracks and their indices
		selectTrackTime=newArray(-4,1,nTime);
		Traverse_All_Track_Points(x,y,t,trackNormalIndices,trackCenters,nTrackArray,selectTrackTime,trnsprncGrdnt);
		Dialog.create("Saving image(s) with tracks");
		Dialog.addChoice("What to save?", newArray("Nothing","First frame + Tracks","All frames + Tracks"));
		Dialog.show();
		dummy_1 =  Dialog.getChoice();
		if (dummy_1 == "First frame + Tracks") {
			if (roiManager("count") > 0)	{
				dummy_2 = roiManager("count");
				roiManager("Deselect");
				roiManager("Delete");
				wait(1);
				print("ROI Manager cleared of "+dummy_2+" entries (ahead of saving superimposed tracks)");
			}
			run("To ROI Manager");
			roiManager("Show All without labels");			
			setSlice(1);
			run("Duplicate...", "title=[Frame_1]");
			selectWindow("Frame_1");
			wait(1);
			roiManager("Deselect");
			run("From ROI Manager");
			run("Select None");
			wait(1);
			saveAs("tiff");
			wait(1);
			roiManager("Deselect");
			roiManager("Delete");
			wait(1);
			selectWindow("Frame_1.tif");
			wait(1);
			close();
			wait(1);
			selectWindow(imageTitle);
		} else if (dummy_1 == "All frames + Tracks") {
			roiManager("Show All without labels");			
			saveAs("tiff");
		}
		wait(1);

		waitForUser("Selecting Track & Time Interval");
		wait(10);
		selectTrackTime=Select_Track(nTracks);
		
	  	Initialize_ROI_Overlay();
		Define_ROI(selectTrackTime);

		Dialog.create("ROIs definition");
		Dialog.addCheckbox("Repeat?",false);
		Dialog.show();
		continueFlag = Dialog.getCheckbox();
		run("Remove Overlay");
		wait(1);
  	}

	run("Close All");
	wait(100);
	
	return 0;
}

function Run_Measurement() {
	Decimation = 1;
	Delay = 50;
	Delay2 = 1000;

	fileInfo = "(SECOND channel) ";
	newImageFileFull = Load_UseOpen_Image(fileInfo);
	imageTitle = Return_Single_Channel(Messages,newImageFileFull);
	if (Decimation > 1) {
		run("Set... ", "zoom="+(floor(100*Decimation)));
	}

	// Conversion to float (32-bit) format to accommodate negative values
	doWithAnnouncement("Conversion to 32-bit ("+PlusMinus+") + Rolling Ball...",100,250,"32-bit",Delay2);

	waitForUser;wait(100);

	// Rolling Ball background subtraction
	RollingBallRadius = 20;
	Dialog.create("Rolling Ball Background Subtraction");
	Dialog.addNumber("Rolling Ball Radius (zero for no background subtraction)", RollingBallRadius);
	Dialog.show(); 
	RollingBallRadius = parseInt(Dialog.getNumber());
	if (RollingBallRadius != 0) {
		run("Subtract Background...", "rolling="+RollingBallRadius+" stack");
		updateDisplay();
		/*getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
		for (Cntr = 0; Cntr < imageFrames; Cntr++) {
			setSlice(Cntr + 1);
			run("Subtract Background...", "rolling="+RollingBallRadius);
			showProgress(Cntr / imageFrames);
			wait(1);
			//waitForUser;
		}*/
	}
	wait(10);

	I_bkg = 100;
	Dialog.create("Mean Background Subtraction");
	Dialog.addNumber("I_background (zero for no background subtraction)", I_bkg);
	Dialog.show(); 
	I_bkg = parseInt(Dialog.getNumber());
	wait(10);
	if (I_bkg != 0) {
		run("Add...", "value=-"+I_bkg+" stack");
	}
	wait(10);

	continueFlag = true;
	while (continueFlag == true) {
		waitForUser("Loading the ROIs file");
		tableType = "ROIs";
		tableReturn = Load_Table(tableType);
		nROI=nResults();	// Total number of ROI records
		wait(10);
	
		Time = newArray(nROI);
		X = newArray(nROI);
		Y = newArray(nROI);
		for (Cntr = 0; Cntr < nROI; Cntr++) {
			 Time[Cntr] = getResult("Time", Cntr);
			 X[Cntr] = getResult("Oval_ROI_X", Cntr);
			 Y[Cntr] = getResult("Oval_ROI_Y", Cntr);
			 dX = getResult("Oval_ROI_dX", Cntr);
			 dY = getResult("Oval_ROI_dY", Cntr);
			 setSlice(Time[Cntr]);
			 wait(1);
		     makeOval(X[Cntr],Y[Cntr],dX,dY);
		     Overlay.addSelection("#"+toHex(0xff888888));
		     Overlay.setPosition(1,1,Time[Cntr]);
		}
		run("Select None");
	
		//Transferring overlaid ROIs to ROI Manager
		waitForUser("Transferring overlaid ROIs to ROI Manager");
		run("To ROI Manager");
		roiManager("Show All without labels");
		roiManager("Deselect");
		run("Hide Overlay");
		wait(10);
		waitForUser(roiManager("count")+" (unselected) ROIs");
		wait(10);
	
		waitForUser("Clearing the Results Table ahead of measurements");
		run("Clear Results");
		selectWindow("Results");
		run("Close");
		run("Set Measurements...", "area mean integrated redirect=None decimal=1");
		wait(200);

		Dialog.create("Delay setting");
		Dialog.addNumber("Delay", Delay);
		Dialog.show(); 
		Delay = parseInt(Dialog.getNumber());
		wait(1);

		for (Cntr = 0; Cntr < nROI; Cntr++) {
			roiManager("Select", Cntr);
			setSlice(Time[Cntr]);
			run("Measure");
			setResult("Time", nResults() - 1, Time[Cntr]);
			updateResults();
			wait(Delay);
		}
		run("Select None");
		selectWindow("Results");
		wait(100);
		waitForUser("Please save MEASUREMENTS");
		wait(1);
		saveAs("results");
		wait(1);

		Dialog.create("Saving image(s) with ROIs");
		Dialog.addChoice("What to save?", newArray("Nothing","First frame + ROIs","All frames + ROIs"));
		Dialog.show();
		dummy_1 =  Dialog.getChoice();
		if (dummy_1 == "First frame + ROIs") {
			roiManager("Show All without labels");			
			setSlice(1);
			run("Duplicate...", "title=[Frame_1]");
			selectWindow("Frame_1");
			wait(1);
			roiManager("Deselect");
			run("From ROI Manager");
			run("Select None");
			wait(1);
			saveAs("tiff");
			wait(1);
			roiManager("Deselect");
			roiManager("Delete");
			wait(1);
			selectWindow("Frame_1.tif");
			wait(1);
			close();
			wait(1);
			selectWindow(imageTitle);
		} else if (dummy_1 == "All frames + ROIs") {
			setSlice(1);setColor(0xff, 0x99, 0x0);setFont("Serif", 28, "antialiased");
			doWithAnnouncement("Enhancing Contrast ...",80,250,"DLE16Enhance Contrastsaturated=0.35",Delay);
			roiManager("Deselect");
			run("Select None");
			for (Cntr = 0; Cntr < nROI; Cntr++) {
				selectWindow(imageTitle);
				setSlice(Time[Cntr]);
				if (Cntr > 0) {
					Overlay.remove;
					wait(1);
				}
				makeOval(X[Cntr],Y[Cntr],dX,dY);
				Overlay.addSelection("#"+toHex(0x00ff0000));
				Overlay.setPosition(1,1,Time[Cntr]);
				run("Overlay Options...", "stroke=red width=2 fill=none set");
				run("Select None");
				wait(1);
				run("Flatten", "slice");
				wait(1);
			}
			selectWindow(imageTitle);
			wait(1);
			close();
			wait(1);
			waitForUser;
			run("Concatenate...", "all_open title=[Frames with flattened corresponding ROIs]");
			wait(1);
			saveAs("tiff");
			wait(1);
			roiManager("Deselect");
			roiManager("Delete");
			wait(1);
		}
		wait(1);


		Dialog.create("New Measurement");
		Dialog.addCheckbox("Repeat?",false);
		Dialog.show();
		continueFlag = Dialog.getCheckbox();
		run("Remove Overlay");
		wait(1);
	}
	run("Close All");
	wait(100);
	return 0;
}

function Run_Visualization() {
	if (getBoolean("Demo of Multiple Measurements?")) {
		Varargin=newArray("");
		Test_Plot(Varargin);
		return;
	}
	
	if (getBoolean("Plotting a Bifurcation Diagram?")) {
		bifurcationParameters = Get_Bifurcation_Parameters();
		Bifurcation_Diagram(bifurcationParameters);
		return;
	}

	tableType = "Measurements";
	Load_Table(tableType);
	nMeasurements=nResults();	// Total number of ROI records
	
	waitForUser("Loading Measurements from the Results Table");
	Time = newArray(nMeasurements);
	v=newArray(nMeasurements);
	for (Cntr = 0; Cntr < nMeasurements; Cntr++) {
		Time[Cntr] = getResult("Time",Cntr);
		v[Cntr] = getResult("IntDen",Cntr);
	}
	Array.getStatistics(Time,TMin,TMax,TMean,TStd);

	missingMeasurement = "NaN";
	trimDataFlag = true;
	continueFlag = true;
	while (continueFlag == true) {
		Dialog.create("Trimming Measurements?");
		Dialog.addNumber("Minimum Time",TMin);
		Dialog.addNumber("Maximum Time",TMax);
		Dialog.addCheckbox("NaNs instead of missing data",trimDataFlag);
		Dialog.show();
		TMin_ = Dialog.getNumber();
		TMax_ = Dialog.getNumber();
		trimDataFlag = Dialog.getCheckbox();
		
		continueFlag = false;
		if (TMin_ < 1) {
			waitForUser("Error: Wrong value of Minimum Time");
			continueFlag = true;
		}
		if (TMax_ < TMin_) {
			waitForUser("Error: Maximum Time smaller than Minimum Time");
			continueFlag = true;
		}
		if (TMax_ < TMax) {
			waitForUser("Error: Maximum Time should be larger than or equal to "+TMax);
			continueFlag = true;
		}
		if (TMin_ > TMin) {
			waitForUser("Error: Minimum Time should be smaller than or equal to "+TMin);
			continueFlag = true;
		}
	}

	// Appending NaNs to the end
	if (TMax_ > TMax) {
		nDiff = TMax_ - TMax;
		tempTime = newArray(nMeasurements + nDiff);
		tempV = newArray(nMeasurements + nDiff);
		for (Cntr = 0; Cntr < nMeasurements; Cntr++) {
			tempTime[Cntr] = Time[Cntr];
			tempV[Cntr] = v[Cntr];
		}
		for (Cntr = 0; Cntr < nDiff; Cntr++) {
			tempTime[nMeasurements + Cntr] = TMax + Cntr + 1;
			tempV[nMeasurements + Cntr] = missingMeasurement;
		}
		Time = tempTime;
		v = tempV;
		TMax = TMax + nDiff;
		nMeasurements = nMeasurements + nDiff;
		nDiffEnd = nDiff;
		updateResultsFlag = true;
	}

	// Appending NaNs to the beginning
	if (TMin_ < TMin) {
		nDiff = TMin - TMin_;
		tempTime = newArray(nMeasurements + nDiff);
		tempV = newArray(nMeasurements + nDiff);
		for (Cntr = 0; Cntr < nDiff; Cntr++) {
			tempTime[Cntr] = TMin_ + Cntr;
			tempV[Cntr] = missingMeasurement;
		}
		for (Cntr = 0; Cntr < nMeasurements; Cntr++) {
			tempTime[nDiff + Cntr] = Time[Cntr];
			tempV[nDiff + Cntr] = v[Cntr];
		}
		Time = tempTime;
		v = tempV;
		TMin = TMin - nDiff;
		nMeasurements = nMeasurements + nDiff;
		nDiffBeginning = nDiff;
		updateResultsFlag = true;
	}

	updateResultsFlag = false;
	if (trimDataFlag == true) {
		// Inserting NaNs
		nMeasurementsFull = TMax - TMin + 1;
		tempTime = newArray(nMeasurementsFull);
		tempV = newArray(nMeasurementsFull);
		for (Cntr = 0; Cntr < nMeasurementsFull; Cntr++) {
			tempTime[Cntr] = TMin + Cntr;
			tempV[Cntr] = missingMeasurement;
		}
		for (Cntr = 0; Cntr < nMeasurements; Cntr++) {
			tempV[Time[Cntr] - TMin] = v[Cntr];
		}
		Time = tempTime;
		v = tempV;
		nMeasurements = TMax - TMin + 1;
		nDiffMiddle = nMeasurementsFull - nMeasurements;
		updateResultsFlag = true;
	}

	if (updateResultsFlag == true) {
		waitForUser("Clearing and updating the Results Table");
		run("Clear Results");
		selectWindow("Results");
		wait(200);
		for (Cntr = 0; Cntr < nMeasurements; Cntr++) {
			setResult("IntDen", Cntr, v[Cntr]);
			setResult("Time", Cntr, Time[Cntr]);
			updateResults();
			wait(50);
		}
		wait(100);
		waitForUser("Please save VISUALIZED Data");
		saveAs("results");
		wait(1);
	}

	
	Array.getStatistics(v,vMin,vMax,vMean,vStd);
	Array.getStatistics(Time,TMin,TMax,TMean,TStd);
	Plot.create(nMeasurements+" calculations of (integrated) intensity: I( X"+"(t), Y"+"(t), t, C)", "Time", "Intensity (given Channel)", Time, v);
	Plot.setLimits(TMin, TMax, vMin, vMax);	
	Plot.show;
	wait(1000);
	imageID = getImageID();
	return imageID;
}

function doWithAnnouncement(Message,PositionX,PositionY,Command,Delay) {
	Overlay.remove();
	run("Remove Overlay");
	Overlay.drawString(Message,PositionX,PositionY);
	Overlay.show();
	if (Delay > 0) {
		wait(Delay);
	}
	print("\\Clear");
	if (startsWith(substring(Command,0,3),"DLE")) {
		Command_1_length =  substring(Command,3,3+2);
		Command_1 = substring(Command,5,5+Command_1_length);
		Command_2 = substring(Command,5+Command_1_length);
		if (Message == "Saving ...") {
			Overlay.remove();
			run("Remove Overlay");
			wait(100);
			print("Overlay removed before saving image");
		}
		run(Command_1,Command_2);
	} else {
		if (Command == "Monitor Memory...") {
			doCommand(Command);
		} else {
			run(Command);
		}
	}
	Overlay.remove();
}

function Return_Single_Channel(Messages,newImageFileFull) {
	Delay = 1000;
	if (getInfo("window.type") != "Image") {
		imageTitle = NaN;
		print("Non-image window ("+getInfo("window.type")+") used as image source.");
	} else {
		pathName = File.directory;
		fileName = File.nameWithoutExtension;
		if (endsWith(getTitle(),"tiff")) {
			Extension = ".tiff";
		} else {
			Extension = ".tif";
		}
		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
		if (imageChannels > 1) {
			Channels = newArray(imageChannels);
			for (cntr = 0; cntr < imageChannels; cntr++) {
				Channels[cntr] = cntr + 1;
			}
			cFlag = true;
			while (cFlag == true) {
				Dialog.create("Choice of channel");
				Dialog.addChoice("The Following channel will be USED (along with tracks):", Channels);
				Dialog.show();
				sCh = parseInt(Dialog.getChoice());
				if (Messages == "Auxiliary") {
					if (getBoolean("Defining an auxiliary channel (for mere monitoring)?") == true) {
						Dialog.create("Choice of AUXILIARY channel");
						Dialog.addChoice("The Following channel will also be MONITORED:", Channels);
						Dialog.show();
						sChAux = parseInt(Dialog.getChoice());
						if (sChAux != sCh) {
							cFlag = false;
						} else {
							waitForUser("The Main channel ("+sCh+") and the Auxiliary channel ("+sChAux+") should be different!");
							wait(1);
						}
					} else {
						sChAux = 0;
						cFlag = false;
					}
				} else {
					sChAux = 0;
					cFlag = false;
				}
			}
			doWithAnnouncement("Splitting Channels ...",100,250,"Split Channels",Delay);
			for (cntr = 0; cntr < imageChannels; cntr++) {
				if (((cntr + 1) != sCh) & ((cntr + 1) != sChAux)) {
					selectWindow("C"+(cntr + 1)+"-"+fileName+Extension);
					doWithAnnouncement("Closing Channel "+(cntr + 1)+" ...",100,250,"Close",Delay);
				}
			}
			//doWithAnnouncement("LUT Change to Gray...",100,250,"Grays",Delay);
			sCh = "C"+sCh+"-";
			sChAux = "C"+sChAux+"-";
		} else {
			sCh = "";
			sChAux = "C0-";
		}		

		imageTitle = sCh+fileName+Extension;
		imageAuxTitle = sChAux+fileName+Extension;

		selectWindow(imageTitle);
		wait(10);
		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
		if ((imageSlices > 1) | (imageFrames > 1)) {
			if (imageFrames == 1) {
				waitForUser("Apparent z-stack interpreted as image sequence");
				imageFrames = imageSlices;
				imageSlices = 1;
				run("Properties...", "channels="+imageChannels+" slices="+imageSlices+" frames="+imageFrames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");			
				if (sChAux != "C0-") {
					selectWindow(imageAuxTitle);
					run("Properties...", "channels="+imageChannels+" slices="+imageSlices+" frames="+imageFrames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");			
					selectWindow(imageTitle);
				}
				getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
			} else if (imageSlices == 1) {
			} else {
				waitForUser("Simultaneous z and t stacks are not allowed.");
				return -1;
			}
		} else if (imageFrames > 1)  {
			waitForUser("An image sequence is required.");
			return -1;
		}
	}
	doWithAnnouncement("Removing Size Calibration ...",100,250,"DLE13Properties...channels="+imageChannels+" slices="+imageSlices+" frames="+imageFrames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000",Delay);
	if (sChAux != "C0-") {
		selectWindow(imageAuxTitle);
		doWithAnnouncement("Removing Size Calibration ...",100,250,"DLE13Properties...channels="+imageChannels+" slices="+imageSlices+" frames="+imageFrames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000",Delay);
		selectWindow(imageTitle);

		selectWindow(imageTitle);
		wait(10);
		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
		waitForUser("Rearrenging t-stack as z-stack");
		wait(1);
		imageSlices = imageFrames;
		imageFrames = 1;
		run("Properties...", "channels="+imageChannels+" slices="+imageSlices+" frames="+imageFrames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");			
		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);

		selectWindow(imageAuxTitle);
		wait(10);
		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
		waitForUser("Rearrenging t-stack as z-stack");
		wait(1);
		imageSlices = imageFrames;
		imageFrames = 1;
		run("Properties...", "channels="+imageChannels+" slices="+imageSlices+" frames="+imageFrames+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");			
		getDimensions(imageWidth, imageHeight, imageChannels, imageSlices, imageFrames);
	}
	selectWindow(imageTitle);
	wait(10);
	if (sChAux != "C0-") {
		imageTitle = newArray(imageTitle,imageAuxTitle);
	}
	return imageTitle;
}

function Load_Table(tableType) {
	if (tableType != "Measurements") {
		run("Set Measurements...", "redirect=None decimal=1");
	}
	useFile = true;
	if (nResults != 0) {
		Dialog.create("Source of "+tableType);
		Dialog.addChoice(tableType+" are to be imported from", newArray("File","Result Table"));
		Dialog.show(); 
		if (Dialog.getChoice() != "File") {
			useFile = false;
		}
	}
	if (useFile) {
		if (nResults != 0) {
			run("Clear Results");
			updateResults();
		}
		if (isOpen("Results") == false) {
			run("Results");
		}
		selectWindow("Results");
		run("Input/Output...", "jpeg=85 gif=-1 file="+tableFileExtension+" copy_column save_column");
		filePath = File.openDialog("Select the "+tableType+" File");
		print("filePath = "+filePath);
		run("Results... ","open="+"["+filePath+"]");
		waitForUser;
		//selectWindow("Results");
		wait(1);
	}
	return 0;
}

function Load_UseOpen_Image(fileInfo) {
	useFile = true;
	if (nImages == 1) {
		Dialog.create("Source of Image Sequence");
		Dialog.addChoice("Image Sequence "+fileInfo+"is to be imported from", newArray("Current Image","File"));
		Dialog.show(); 
		if (Dialog.getChoice() != "File") {
			useFile = false;
		}
	}
	if (useFile) {
		run("Close All");
		wait(100);
		newImageFileFull = File.openDialog("Select the Image sequence "+fileInfo);
		open(newImageFileFull);
	}
	return newImageFileFull;
}

function Form_Save_Load_Hyperstack() {
 	batchFlag = is("Batch Mode");
 	setBatchMode(true);
 	wait(1);
 	
 	folderNameRed = getDirectory("Choose the "+DQ+"RED channel"+DQ+" folder");
	fileListRed = getFileList(folderNameRed);
	nRed = lengthOf(fileListRed);

	folderNameGreen = getDirectory("Choose the "+DQ+"GREEN channel"+DQ+" folder");
	fileListGreen = getFileList(folderNameGreen);
	nGreen = lengthOf(fileListGreen);

	if (nRed != nGreen) {
		waitForUser("Error: Red- and Green-channel folders have different numbers of images");
		return -1;
	} else {
		waitForUser(nRed+" images per (Red/Green) channel");
	}
	
	run("Close All");
	wait(100);
	for (cntr = 0; cntr < nRed; cntr++) {
		open(folderNameRed+fileListRed[cntr]);
	}
	wait(10);
	run("Images to Stack", "name=Red_Stack title=[] use");
	wait(10);
	imageRed = getList("image.titles");
	saveAs("Tiff", folderNameRed+imageRed[0]);

	run("Close All");
	wait(100);
	for (cntr = 0; cntr < nGreen; cntr++) {
		open(folderNameGreen+fileListGreen[cntr]);
	}
	wait(10);
	run("Images to Stack", "name=Green_Stack title=[] use");
	wait(10);
	imageGreen = getList("image.titles");
	saveAs("Tiff", folderNameGreen+imageGreen[0]);

	open(folderNameRed+imageRed[0]+".tif");

	run("Merge Channels...", "c1="+imageRed[0]+".tif"+" c2="+imageGreen[0]+".tif"+" create");
	if (isOpen(imageRed[0])) {
		close(imageRed[0]);
	}
	if (isOpen(imageGreen[0])) {
		close(imageGreen[0]);
	}
	imageRG = getList("image.titles");

	saveAs("Tiff", folderNameGreen+imageRG[0]);
	run("Close All");
	wait(100);
 	setBatchMode(batchFlag);
 	wait(100);
	open(folderNameGreen+imageRG[0]+".tif");
 	wait(10);

 	return 0;
}

function Manual_Tracking(imageTitle) {
	intelligentFlag = true;
	tableFileExtension = "csv";
	Delay = 1000;
	sHift = 0x01;
	leftClick = 0x10;
	leftClickShift = leftClick + sHift;

	imageID = getImageID();
 	getDimensions(iWidth, iHeight, iChannels, iSlices, iFrames);
 	nSlices_ = iSlices*iFrames;

 	sliceIndex = 1;

	if (roiManager("count") > 0)	{
	 roiManager("Deselect");
	 roiManager("Delete");
	}
	waitForUser("Please define and tailor a (rectangular) ROI; then Ctrl+T");
	while (roiManager("count") == 0)	{
	}
	wait(1);
	selectWindow(imageTitle);
	wait(1);
	roiManager("Select", 0);
	wait(1);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside", "stack");
	//run("Cyan");
	if (getBoolean("Filtering the images?")) {
		setSlice(1);setColor(0xff, 0x99, 0x0);setFont("Serif", 28, "antialiased");
		doWithAnnouncement("Median Filtering ...",80,250,"DLE09Median...radius=4 stack",Delay);
		doWithAnnouncement("Low-Pass Filtering ...",80,250,"DLE16Gaussian Blur...sigma=2 stack",Delay);
	}
	selectWindow(imageTitle);
	wait(1);
	/*if (getBoolean("Enhancing the contrast?")) {
		doWithAnnouncement("Enhancing Contrast ...",80,250,"DLE16Enhance Contrastsaturated=0.35",Delay);
	}*/
	selectWindow(imageTitle);
	wait(1);
	if (getBoolean("Thresholding the images?")) {
		setSlice(1);setColor(0xff, 0x99, 0x0);setFont("Serif", 28, "antialiased");
		run("Threshold...");
		wait(100);
		cntFlag = true;
		while (cntFlag == true) {
			list = getList("window.titles");
			isThreshold = false;
			for (dummy_1 = 0; dummy_1 < list.length; dummy_1++) {
				if (list[dummy_1] == "Threshold") {
					isThreshold = true;
				}
			}
			cntFlag = isThreshold;
		}
	}
	selectWindow(imageTitle);
	wait(1);

 	//xDiameter = round(iWidth / 16);
 	//yDiameter = round(iHeight / 16);
 	//xOval = round(iWidth / 2);
 	//yOval = round(iHeight / 2);
 	xDiameter = 20;
 	yDiameter = 20;

	trackIndex = 1;
	
	Dialog.create("ROI Parameters");
	Dialog.addNumber("Track Index:", trackIndex); 	
	Dialog.addNumber("ROI Diameter (Horizontal):", xDiameter); 	
	Dialog.addNumber("ROI Diameter (Vertical):", yDiameter);
	Dialog.show();
	wait(1);
	trackIndex = Dialog.getNumber(); 	
	xDiameter = Dialog.getNumber(); 	
	yDiameter = Dialog.getNumber();
	diameterROI = newArray(xDiameter, yDiameter);
	
	run("Set Measurements...", "area mean integrated redirect=None decimal=1");
	//run("Set Measurements...", "redirect=None decimal=1");
	updateResults();
	run("Clear Results");
	xROI = newArray(nSlices_);
	yROI = newArray(nSlices_);
	tROI = newArray(nSlices_);

	estimatedShiftDiameter = 8;
	estimatedShiftDiameter = round(getNumber("Estimated Cell Movement",estimatedShiftDiameter));
	
	waitForUser("Left-Click at ROI centers (to be defined); Shift+Left-Click to end");
	bestROI = newArray("NaN");
 	sliceIndex = 1;
 	cntr = 0;
 	continueFlag = true;
	while (continueFlag == true) {
		selectImage(imageID);
		wait(1);
		if (sliceIndex == 1) {
			setSlice(sliceIndex);
		} else {
			run("Next Slice [>]");
		}
		wait(1);
		clickContinueFlag = true;
		while (clickContinueFlag == true) {
			selectImage(imageID);
			wait(1);
			sliceIndex = getSliceNumber();
			if ((cntr > 0) & intelligentFlag) {
				lastPoint=newArray(xROI[cntr - 1],yROI[cntr - 1]);
				bestROI = Estimate_Best_ROI(lastPoint, estimatedShiftDiameter, diameterROI, sliceIndex);
				Navigate_Neighborhood(bestROI, estimatedShiftDiameter, lastPoint);
				releaseFlag = false;
			} else {
				releaseFlag = true;
			}
			leftClick = Wait_For_LeftClick(bestROI, releaseFlag);

			clickContinueFlag = false;
			if ((leftClick[3] & sHift) == 0) {
				sliceIndex = getSliceNumber();
				//cntr = sliceIndex - 1;
				xROI[cntr] = leftClick[0];
				yROI[cntr] = leftClick[1];
				//tROI[cntr] = sliceIndex - 1;
				tROI[cntr] = sliceIndex;
				
				xOval = leftClick[0] - xDiameter / 2;
				yOval = leftClick[1] - yDiameter / 2;
				
				//print("xOval = "+(xOval-xDiameter/2)+", yOval = "+(yOval-yDiameter/2)+", xDiameter = "+xDiameter+", yDiameter = "+yDiameter);
				//makeOval((xOval - (xDiameter / 2)),(yOval - (yDiameter / 2)),xDiameter, yDiameter);
				//print("xOval = "+xOval+", yOval = "+yOval+", xDiameter = "+xDiameter+", yDiameter = "+yDiameter);
				makeOval(xOval,yOval,xDiameter, yDiameter);
				Color=(sliceIndex/nSlices_)*0x0000ff+0.1*0x00ff00+(1-sliceIndex/nSlices_)*0xff0000;
				Transparency=0;
				//Overlay.addSelection("",0,"#"+toHex(Transparency)+toHex(Color));
				Overlay.addSelection("#"+toHex(Transparency)+toHex(Color));
				Overlay.setPosition(1,1,sliceIndex);
				Overlay.show();
				//Overlay.activateSelection(0);
				//while (getInfo("selection.name") == "") {
				//	print("Overlay not added.");
				//}
				wait(1);

				//Roi.getBounds(xOval, yOval, xDiameter_, yDiameter_);
				getSelectionBounds(xOval_, yOval_, xDiameter_, yDiameter_);
				//print("xOval_ = "+xOval_+", yOval_ = "+yOval_+", xDiameter_ = "+xDiameter_+", yDiameter_ = "+yDiameter_);
				print("");
			} else {
	 			continueFlag = false;
	 			print("Shift + Left-Click detected");
			}
		}
		if (continueFlag == true) {
			if (roiManager("count") > 0)	{
			 roiManager("Deselect");
			 roiManager("Delete");
			}
			run("To ROI Manager");
			roiManager("Show All without labels");
			roiManager("Deselect");
			roiManager("Select",0);
	

			//updateResults();
			//selectWindow("Results");
			//wait(100);
			run("Measure");
			wait(300);

			selectWindow("Results");
			setResult("Time", cntr, tROI[cntr]);
			setResult("Oval_ROI_X", cntr, xROI[cntr] - xDiameter/2);
			setResult("Oval_ROI_Y", cntr, yROI[cntr] - yDiameter/2);
			setResult("Global_Track_Index", cntr, trackIndex);
			setResult("Oval_ROI_dX", cntr, xDiameter);
			setResult("Oval_ROI_dY", cntr, yDiameter);
			setResult("Track Index", cntr, trackIndex);
			setResult("Measurement", cntr, NaN);
			updateResults();

			run("Select None");
			run("Remove Overlay");
			//Overlay.show();
			roiManager("Deselect");
			roiManager("Delete");
			wait(100);
			
			sliceIndex++;
			cntr++;
			if (sliceIndex > nSlices_) {
	 			//sliceIndex = 1;
		 		continueFlag = false;
			}
		} else {
			//x = Array.slice(xROI,0,sliceIndex);
			//y = Array.slice(yROI,0,sliceIndex);
			//Timne = Array.slice(tROI,0,sliceIndex);

			//run("Set Measurements...", "redirect=None decimal=1");
			print("nResults = "+nResults);
			run("Select None");
			selectWindow("Results");
			wait(1);
		
			run("Input/Output...", "jpeg=85 gif=-1 file="+tableFileExtension+" copy_column save_column");
			waitForUser("Please save ROIs");
			saveAs("results");
			wait(10);
		}
 	}
}

function Wait_For_ShiftLeftClick() {
	sHift = 0x01;
	leftClick = 0x10;

	//Wait till left mouse button released
	flags = 0x00;
	continueFlag = true;
	while (continueFlag) {
		getCursorLoc(x, y, z, flags);
		if ((flags & leftClick) == 0) {
			continueFlag = false;
		}
	}
	
	continueFlag = true;
	while (continueFlag) {
		//Wait till Shift + Left mouse button pressed
		flags = 0x00;
		continueFlag2 = true;
		while (continueFlag2 == true) {
			getCursorLoc(x, y, z, flags);
			if (((flags & leftClick) != 0) & ((flags & sHift) != 0)) {
				continueFlag2 = false;
			}
		}

		//Debounce: 1) Wait
		wait(10);

		//Debounce: 2) Verify if Shift + Left mouse button still clicked
		flags = 0x00;
		getCursorLoc(x, y, z, flags);
		if (((flags & leftClick) != 0) & ((flags & sHift) != 0)) {
			continueFlag = false;
		}
	}
	return newArray(x,y,z,flags);
}

function Wait_For_LeftClick(bestROI, releaseFlag) {
	sHift = 0x01;
	leftClick = 0x10;

	if (releaseFlag) {
		//Wait till left mouse button released
		flags = 0x00;
		continueFlag = true;
		while (continueFlag) {
			getCursorLoc(x, y, z, flags);
			if ((flags & leftClick) == 0) {
				continueFlag = false;
			}
		}
	}
	
	continueFlag = true;
	while (continueFlag) {
		//Wait till Left mouse button pressed
		flags = 0x00;
		continueFlag2 = true;
		while (continueFlag2 == true) {
			getCursorLoc(x, y, z, flags);
			if ((flags & leftClick) != 0) {
				continueFlag2 = false;
			}
		}

		//Debounce: 1) Wait
		wait(10);

		//Debounce: 2) Verify if Left mouse button still clicked
		flags = 0x00;
		getCursorLoc(x, y, z, flags);
		if ((flags & leftClick) != 0) {
			continueFlag = false;
			if (releaseFlag == false) {
				//Wait till left mouse button released
				continueFlag_ = true;
				while (continueFlag_) {
					getCursorLoc(x_, y_, z_, flags_);
					if ((flags_ & leftClick) == 0) {
						continueFlag_ = false;
					}
				}
			}
		}
	}
	return newArray(x,y,z,flags);
}

function Test_Plot(Varargin) {
 	filePath = getDirectory("Choose the FOLDER of (synchronized) Measurement files (file names starting with MEAS)");
	fileListOriginal = getFileList(filePath);
	nFilesOriginal = lengthOf(fileListOriginal);
	fileList = newArray(nFilesOriginal);
	nFiles = 0;
	for (cntr = 0; cntr < nFilesOriginal; cntr++) {
		//if (endsWith(fileListOriginal[cntr],"Append"))
		if (startsWith(fileListOriginal[cntr],"Meas"))
			fileList[nFiles++] = fileListOriginal[cntr];
	}
	fileList = Array.slice(fileList,0,nFiles);
	run("Clear Results");
	run("Results... ","open="+"["+filePath+fileList[1]+"]");
	nData = nResults - 2;

	run("Clear Results");
	nTotal = nData * nFiles;
	imageParams = newArray("Test Image","32-bit",nData,nFiles,"1");
	imageID = Create_Image(imageParams);
	run("Remove Overlay");
	for (cntr = 0; cntr < nFiles; cntr++) {
		run("Clear Results");
		run("Results... ","open="+"["+filePath+fileList[cntr]+"]");
		for (cntrD = 0; cntrD < nData; cntrD++) {
			//print("cntr = "+cntr+", cntrD = "+cntrD+", file = "+fileList[cntr]);
			setPixel(cntrD,cntr,getResult("Measurement", cntrD));
		}
	}
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	for (cntr = 0; cntr < nFiles; cntr++) {
		for (cntrD = 0; cntrD < nData; cntrD++) {
			setPixel(cntrD,cntr,getPixel(cntrD,cntr)/max);
		}
		makeLine(0, cntr, (nData - 1), cntr);
		run("Add Selection...");
	}
	run("To ROI Manager");
	roiManager("Deselect");
	run("Remove Overlay");
	run("Select None");
	run("Enhance Contrast", "saturated=0.0");
	run("Cyan");
	run("Calibration Bar...", "location=[Upper Right] fill=White label=[Dark Gray] number=8 decimal=2 font=9 zoom=0.25 overlay");
	run("Set... ", "zoom=600 x=99 y=16");

	Time = newArray(nData);
	for (cntrD = 0; cntrD < nData; cntrD++) {
		Time[cntrD] = (1 + cntrD);
	}
	Array.getStatistics(Time,TMin,TMax,TMean,TStd);
	shownPlot = newArray(nFiles);
	for (cntr = 0; cntr < nFiles; cntr++) {
		shownPlot[cntr] = NaN;
	}

	vMin = 0;
	vMax = 1;
	v = newArray(nData);
	waitForUser("Select an ROI, or [Deselect+Delete] to end");
	wait(1);
	shownPlot_ = NaN;
	contFlag = true;
	//roiManager("Deselect");
	//roiManager("Select",0);
	while(contFlag) {
		roiIndex = roiManager("index");
		if (roiIndex != -1) {
			if (shownPlot_ == shownPlot_) {
				//print("shownPlot_ = "+shownPlot_);
				selectImage(shownPlot_);
				close();
				while (isOpen(shownPlot_)) {
				}
			}
			if (true) {
				selectImage(imageID);
				for (cntrD = 0; cntrD < nData; cntrD++) {
					v[cntrD] = getPixel(cntrD,roiIndex);
				}
				//Array.getStatistics(v,vMin,vMax,vMean,vStd);
				//Plot.create(nData+" calculations of (integrated) intensity: I( X"+"(t), Y"+"(t), t, C)", "Time", "Intensity (given Channel)", Time, v);
				Plot.create(fileList[roiIndex], "Time", "Intensity (given Channel)", Time, v);
				Plot.setLimits(TMin, TMax, vMin, vMax);	
				Plot.show;
 				setLocation(0,0);
				//shownPlot[roiIndex] = getImageID();
				//wait(1);
				shownPlot_ = getImageID();
				//wait(1);
				//run("Select None");
				//roiManager("Deselect");
				selectWindow("ROI Manager");
			} else {
				//selectImage(shownPlot[roiIndex]);
			}
		}
		if (roiManager("count") == 0) {
			contFlag = false;
		}
	}
	varArgOut = newArray("1");
	return varArgOut;
}

function Create_Image(Varargin) {
	nExpected = 5;
	nVarargin = lengthOf(Varargin);
	if (nVarargin < nExpected) {
		return NaN;
	} else {
		imageTitle = Varargin[0];
		imageType = Varargin[1];
		imageWidth = parseInt(Varargin[2]);
		imageHeight = parseInt(Varargin[3]);
		imageDepth = parseInt(Varargin[4]);
		print("");
		print("Image to be synthesized with the following parameters:");
		print("Title: "+imageTitle);
		print("Type: "+imageType);
		print("Width: "+imageWidth);
		print("Height: "+imageHeight);
		print("Depth: "+imageDepth);
		if (nVarargin > nExpected) {
			print("The last "+(nVarargin - nExpected)+" element(s) of the input parameter were discarded.")
		}
	}
	newImage(imageTitle, imageType, imageWidth, imageHeight, imageDepth);
	imageID = getImageID();
	return imageID;
}

function Estimate_Best_ROI(lastPoint, estimatedShiftDiameter, diameterROI, sliceIndex) {
	estimatedShiftTotal = estimatedShiftDiameter * estimatedShiftDiameter;
	minOffset = - round(estimatedShiftDiameter / 2);
	maxOffset = estimatedShiftDiameter - 1 - round(estimatedShiftDiameter / 2);
	estimatedXCenterOffset = newArray(estimatedShiftTotal);
	estimatedYCenterOffset = newArray(estimatedShiftTotal);
	estimatedMeasurement = newArray(estimatedShiftTotal);

	setBatchMode(true);
	IJ.renameResults("Temp");
	while(isOpen("Results")) {
	}
	run("Clear Results");
	run("Set Measurements...", "area mean integrated redirect=None decimal=1");
	Cntr = 0;
	for (cntr1 = 0; cntr1 < estimatedShiftDiameter; cntr1++) {
		for (cntr2 = 0; cntr2 < estimatedShiftDiameter; cntr2++) {
			xCenter = cntr1 + minOffset + lastPoint[0];
			yCenter = cntr2 + minOffset + lastPoint[1];
			makeOval(xCenter - diameterROI[0] / 2, yCenter - diameterROI[1] / 2, diameterROI[0], diameterROI[1]);
			Overlay.addSelection("#"+toHex(0xffff0000));
			Overlay.setPosition(1,1,sliceIndex);
			run("Select None");

			run("To ROI Manager");
			//roiManager("Show All without labels");
			roiManager("Deselect");
			//run("Hide Overlay");
			//wait(1);
			roiManager("Select", 0);
			setSlice(sliceIndex);
			run("Measure");
			updateResults();

			//wait(1);
			estimatedMeasurement[Cntr] = getResult("RawIntDen", nResults() - 1);
			estimatedXCenterOffset[Cntr] = xCenter;
			estimatedYCenterOffset[Cntr++] = yCenter;
			//wait(1);
			run("Clear Results");
		}
	}
	roiManager("Deselect");
	roiManager("Delete");
	run("Remove Overlay");
	run("Select None");
	run("Clear Results");
	while (nResults() > 0) {
	}
	IJ.renameResults("Temp","Results");
	while (nResults() == 0) {
	}
	setBatchMode(false);

	Cntr = 0;
	bestFoFar = - 1.0 / 0.0;
	for (cntr1 = 0; cntr1 < estimatedShiftDiameter; cntr1++) {
		for (cntr2 = 0; cntr2 < estimatedShiftDiameter; cntr2++) {
			if (estimatedMeasurement[Cntr] > bestFoFar) {
				bestFoFar = estimatedMeasurement[Cntr];
				//print("bestFoFar = "+bestFoFar);
				maxPoint = newArray(estimatedXCenterOffset[Cntr], estimatedYCenterOffset[Cntr]);
				maxMeasurement = bestFoFar;
			}
			Cntr++;
		}
	}
	
	bestROI = Array.concat(maxPoint,maxMeasurement);
	bestROI = Array.concat(bestROI,estimatedMeasurement);
	return bestROI;
}

function Navigate_Neighborhood(bestROI, estimatedShiftDiameter, lastPoint) {
	leftClick = 0x10;

	estimatedShiftTotal = estimatedShiftDiameter * estimatedShiftDiameter;
	minOffset = - round(estimatedShiftDiameter / 2);
	maxOffset = estimatedShiftDiameter - 1 - round(estimatedShiftDiameter / 2);

	//bestROI = Array.concat(Array.concat(maxPoint,maxMeasurement),estimatedMeasurement);
	maxPoint = Array.slice(bestROI, 0, 0 + 2);
	maxMeasurement = Array.slice(bestROI, 2, 2 + 1);
	estimatedMeasurement = Array.slice(bestROI, 3, 3 + estimatedShiftTotal);

	xOld = -1.0 / 0.0;
	yOld = -1.0 / 0.0;
	flags = 0x00;
	while ((flags & leftClick) == 0) {
		getCursorLoc(x, y, z, flags);
		matchIndex = 0;
		for (cntr1 = 0; cntr1 < estimatedShiftDiameter; cntr1++) {
			xCenter = cntr1 + minOffset + lastPoint[0];
			for (cntr2 = 0; cntr2 < estimatedShiftDiameter; cntr2++) {
				yCenter = cntr2 + minOffset + lastPoint[1];
				if ((xCenter == x) & (yCenter == y) & (xOld != x) & (yOld != y)) {
					xOld = x;
					yOld = y;
					print("Current: "+estimatedMeasurement[matchIndex]+" @ ("+x+","+y+")"+" and Max = "+maxMeasurement[0]+" @ ("+maxPoint[0]+","+maxPoint[1]+")");
					cntr1 = estimatedShiftDiameter;
					cntr2 = estimatedShiftDiameter;
				}
				matchIndex++;
			}
		}
	}
	return flags;
}

function Get_Bifurcation_Parameters() {
	helpURL = "http://en.wikipedia.org/wiki/Bifurcation_diagram#Logistic_map";
	nPhases = 3;
	addGainFlag = true;
	Dialog.create("Bifurcation Parameters");
	Dialog.addNumber("Number of phases:", nPhases); 	
	Dialog.addCheckbox("Add Gain (flat line for conserved/equal energy)", addGainFlag); 	
	Dialog.addHelp(helpURL);
	Dialog.show();
	wait(1);
	addGainFlag = Dialog.getCheckbox(); 	
	nPhases = Dialog.getNumber();

	nAllPhases = pow(2, nPhases) - 1;
	nParameters = 2 * nAllPhases;
	bifurcationParameters = newArray(nParameters);
	Colors = newArray("blue","red","green","yellow","cyan","magenta","black","gray");
	for (phaseCntr = 1; phaseCntr <= nPhases; phaseCntr++) {
		Cntr = pow(2, phaseCntr - 1) - 1;
		for (subPhaseCntr = 1; subPhaseCntr <= pow(2, phaseCntr - 1); subPhaseCntr++) {
			bifurcationParameters[2 * (Cntr + subPhaseCntr - 1)] = "noFile";
			bifurcationParameters[2 * (Cntr + subPhaseCntr - 1) + 1] = "noColor";
			//print((2 * (Cntr + subPhaseCntr - 1))); print((2 * (Cntr + subPhaseCntr - 1) + 1));
		}
		for (subPhaseCntr = 1; subPhaseCntr <= pow(2, phaseCntr - 1); subPhaseCntr++) {
			fileDescription = "Sub Phase "+subPhaseCntr+" of Phase "+phaseCntr;
			if (getBoolean("Selecting "+fileDescription+"?")) {
				bifurcationParameters[2 * (Cntr + subPhaseCntr - 1)] = File.openDialog("Select the file corresponding to "+fileDescription);
				bifurcationParameters[2 * (Cntr + subPhaseCntr - 1) + 1] = Colors[subPhaseCntr - 1];
			} else {
				subPhaseCntr = phaseCntr + 1;
			}
		}
	}
	bifurcationParameters = Array.concat(addGainFlag,bifurcationParameters);
	return bifurcationParameters;
}

function Bifurcation_Diagram(bifurcationParameters) {
	addGainFlag = bifurcationParameters[0];
	bifurcationParameters = Array.slice(bifurcationParameters,1);
	nParameters = lengthOf(bifurcationParameters);
	nAllPhases = round(nParameters / 2);
	nPhases = round( log(nAllPhases + 1) / log(2) );
	//print("nParameters = "+nParameters+", nAllPhases = "+nAllPhases+", nPhases = "+nPhases);

	subPhaseFileName = bifurcationParameters[0];
	subPhaseColor = bifurcationParameters[1];
	minValue = 0;
	maxValue = 0;
	for (phaseCntr = 1; phaseCntr <= nPhases; phaseCntr++) {
		Cntr = pow(2, phaseCntr - 1) - 1;
		gainFactor = pow(2, addGainFlag * (phaseCntr - 1) );
		for (subPhaseCntr = 1; subPhaseCntr <= pow(2, phaseCntr - 1); subPhaseCntr++) {
			fileDescription = "Sub Phase "+subPhaseCntr+" of Phase "+phaseCntr;
			subPhaseFileName = bifurcationParameters[2 * (Cntr + subPhaseCntr - 1)];
			subPhaseColor = bifurcationParameters[2 * (Cntr + subPhaseCntr - 1) + 1];
			if (subPhaseColor != "noColor") {
				run("Clear Results");
				run("Results... ","open="+"["+subPhaseFileName+"]");
				nData = nResults;
				Time = newArray(nData);
				Measurement = newArray(nData);
				for (cntrD = 0; cntrD < nData; cntrD++) {
					Time[cntrD] = (1 + cntrD);
					Measurement[cntrD] = gainFactor * getResult("Measurement", cntrD);
				}
				Array.getStatistics(Time,TMin,TMax,TMean,TStd);
				Array.getStatistics(Measurement,MMin,MMax,MMean,MStd);
				if (MMin < minValue) {
					minValue = MMin;
				}
				if (MMax > maxValue) {
					maxValue = MMax;
				}
			}
		}
	}

	
	subPhaseFileName = bifurcationParameters[0];
	subPhaseColor = bifurcationParameters[1];
	for (phaseCntr = 1; phaseCntr <= nPhases; phaseCntr++) {
		Cntr = pow(2, phaseCntr - 1) - 1;
		gainFactor = pow(2, addGainFlag * (phaseCntr - 1) );
		for (subPhaseCntr = 1; subPhaseCntr <= pow(2, phaseCntr - 1); subPhaseCntr++) {
			fileDescription = "Sub Phase "+subPhaseCntr+" of Phase "+phaseCntr;
			subPhaseFileName = bifurcationParameters[2 * (Cntr + subPhaseCntr - 1)];
			subPhaseColor = bifurcationParameters[2 * (Cntr + subPhaseCntr - 1) + 1];
			if (subPhaseColor != "noColor") {
				run("Clear Results");
				run("Results... ","open="+"["+subPhaseFileName+"]");
				nData = nResults;
				Time = newArray(nData);
				Measurement = newArray(nData);
				for (cntrD = 0; cntrD < nData; cntrD++) {
					Time[cntrD] = (1 + cntrD);
					Measurement[cntrD] = gainFactor * getResult("Measurement", cntrD);
				}
				if ((phaseCntr * subPhaseCntr) == 1) {
					Plot.create("Bifurcation Plot", "Time", "Intensity"); 
					Plot.setLimits(TMin,TMax,minValue,maxValue);
				}
				Plot.setColor(subPhaseColor); 
				Plot.add("line",Time,Measurement); 				
			}
		}
	}
	Plot.show();
	return;
	

	
	
	
	filePath = getDirectory("Choose the FOLDER of (synchronized) Measurement files (file names starting with MEAS)");
	fileListOriginal = getFileList(filePath);
	nFilesOriginal = lengthOf(fileListOriginal);
	fileList = newArray(nFilesOriginal);
	nFiles = 0;
	for (cntr = 0; cntr < nFilesOriginal; cntr++) {
		//if (endsWith(fileListOriginal[cntr],"Append"))
		if (startsWith(fileListOriginal[cntr],"Meas"))
			fileList[nFiles++] = fileListOriginal[cntr];
	}
	fileList = Array.slice(fileList,0,nFiles);
	run("Clear Results");
	run("Results... ","open="+"["+filePath+fileList[1]+"]");
	nData = nResults - 2;

	run("Clear Results");
	nTotal = nData * nFiles;
	imageParams = newArray("Test Image","32-bit",nData,nFiles,"1");
	imageID = Create_Image(imageParams);
	run("Remove Overlay");
	for (cntr = 0; cntr < nFiles; cntr++) {
		run("Clear Results");
		run("Results... ","open="+"["+filePath+fileList[cntr]+"]");
		for (cntrD = 0; cntrD < nData; cntrD++) {
			//print("cntr = "+cntr+", cntrD = "+cntrD+", file = "+fileList[cntr]);
			setPixel(cntrD,cntr,getResult("Measurement", cntrD));
		}
	}
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	for (cntr = 0; cntr < nFiles; cntr++) {
		for (cntrD = 0; cntrD < nData; cntrD++) {
			setPixel(cntrD,cntr,getPixel(cntrD,cntr)/max);
		}
		makeLine(0, cntr, (nData - 1), cntr);
		run("Add Selection...");
	}
	run("To ROI Manager");
	roiManager("Deselect");
	run("Remove Overlay");
	run("Select None");
	run("Enhance Contrast", "saturated=0.0");
	run("Cyan");
	run("Calibration Bar...", "location=[Upper Right] fill=White label=[Dark Gray] number=8 decimal=2 font=9 zoom=0.25 overlay");
	run("Set... ", "zoom=600 x=99 y=16");

	Time = newArray(nData);
	Measurement = newArray(nData);
	for (cntrD = 0; cntrD < nData; cntrD++) {
		Time[cntrD] = (1 + cntrD);
		Measurement[cntrD] = getResult("Measurement", cntrD);
	}
	Array.getStatistics(Time,TMin,TMax,TMean,TStd);
	Array.getStatistics(Measurement,MMin,MMax,MMean,MStd);
	shownPlot = newArray(nFiles);
	for (cntr = 0; cntr < nFiles; cntr++) {
		shownPlot[cntr] = NaN;
	}

	vMin = 0;
	vMax = 1;
	v = newArray(nData);
	waitForUser("Select an ROI, or [Deselect+Delete] to end");
	wait(1);
	shownPlot_ = NaN;
	contFlag = true;
	//roiManager("Deselect");
	//roiManager("Select",0);
	while(contFlag) {
		roiIndex = roiManager("index");
		if (roiIndex != -1) {
			if (shownPlot_ == shownPlot_) {
				print("shownPlot_ = "+shownPlot_);
				selectImage(shownPlot_);
				close();
				while (isOpen(shownPlot_)) {
				}
			}
			if (true) {
				selectImage(imageID);
				for (cntrD = 0; cntrD < nData; cntrD++) {
					v[cntrD] = getPixel(cntrD,roiIndex);
				}
				//Array.getStatistics(v,vMin,vMax,vMean,vStd);
				//Plot.create(nData+" calculations of (integrated) intensity: I( X"+"(t), Y"+"(t), t, C)", "Time", "Intensity (given Channel)", Time, v);
				Plot.create(fileList[roiIndex], "Time", "Intensity (given Channel)", Time, v);
				Plot.setLimits(TMin, TMax, vMin, vMax);	
				Plot.show;
 				setLocation(0,0);
				//shownPlot[roiIndex] = getImageID();
				//wait(1);
				shownPlot_ = getImageID();
				//wait(1);
				//run("Select None");
				//roiManager("Deselect");
				selectWindow("ROI Manager");
			} else {
				//selectImage(shownPlot[roiIndex]);
			}
		}
		if (roiManager("count") == 0) {
			contFlag = false;
		}
	}
	varArgOut = newArray("1");
	return varArgOut;
}

function Correlation_Analysis(x,y,t) {
	nMax = 5;

	N = lengthOf(x);
	lagMax = t[N - 1] - t[0];
	nMax = minOf(nMax , lagMax);
	corrFunction = newArray(nMax);
	lagVariable = newArray(nMax);
	
	for (lagCntr = 1; lagCntr <= nMax; lagCntr++) {
		lagVariable[lagCntr - 1] = lagCntr;
		dummy_1 = 0;
		dummy_2 = 0;
		for (cntr = 0; cntr < (N - lagCntr); cntr++) {
			if ( (t[cntr + lagCntr] - t[cntr] ) == lagCntr) {
				dummy_1 += pow(x[cntr + lagCntr]-x[cntr],2) + pow(y[cntr + lagCntr]-y[cntr],2) ;
				dummy_2++;
			}
		}
		corrFunction[lagCntr - 1] = dummy_1 / dummy_2;
		print(dummy_2+" pairs used for a time lag of "+lagCntr);
	}

	Array.getStatistics(corrFunction,corrMin,corrMax,corrMean,corrStd);
	Array.getStatistics(lagVariable,LagMin,LagMax,LagMean,LagStd);
	Plot.create("Correlation analysis of the track (diffusion regime estimation)", "Time Lag ("+Delta+"t)", "Mean Distance (d)", lagVariable, corrFunction);
	Plot.setLimits(LagMin, LagMax, corrMin, corrMax);	
	Plot.show;
	wait(1000);
}
