// Program: flowDiagram.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Offers a menu by explicit demonstration of individual steps in the flow diagram. The user sees the entire flow diagram and gets information regarding each step (with a Mouse-over action). At the same time, he can decide which steps, with what orders, and on what data sets should be executed. Such a flexible and informative flow diagram is suited both for beginners and also for experienced users willing to perform customized operations or to modify intermediate results.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	nFDh = 800;
	nFDv = round(nFDh*0.40);

	Initialize();
	mainLoopFlag = true;
	while (mainLoopFlag) {
		if (isOpen("Flow Diagram")) {
			close("Flow Diagram");
			wait(1);
		}
		newImage("Flow Diagram", "8-bit white", nFDh, nFDv, 1);
		a = newArray("gray","gray","gray","gray","gray","gray");
		locationMainBoxes = Update_FD(a, nFDh);
		Index = Get_Mouse_Polling(locationMainBoxes);
		selectWindow("Flow Diagram");
		if (Index == 5) {
			a = newArray("white","white","white","white","white","white");
			locationMainBoxes = Update_FD(a, nFDh);
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
			locationMainBoxes = Update_FD(a, nFDh);
			wait(200);
			close("Flow Diagram");
			wait(1);
			if (Index == 0) {
				dummy_1 = runStep1(Index);
			} else if (Index == 1) {
				dummy_1 = runStep2(Index);
			} else if (Index == 2) {
				dummy_1 = runStep3(Index);
			} else if (Index == 3) {
				dummy_1 = runStep4(Index);
			} else if (Index == 4) {
				dummy_1 = runStep5(Index);
			}
			if (dummy_1 == -1) {
				mainLoopFlag = false;
			}
		}
	}
}

function runStep1(Index) {
	print("Step " + (++Index) + " would be performed.");
	return true;
}

function runStep2(Index) {
	print("Step " + (++Index) + " would be performed.");
	return true;
}

function runStep3(Index) {
	print("Step " + (++Index) + " would be performed.");
	return true;
}

function runStep4(Index) {
	print("Step " + (++Index) + " would be performed.");
	return true;
}

function runStep5(Index) {
	print("Step " + (++Index) + " would be performed.");
	return true;
}

function Initialize() {
	print("\\Clear");

	run("Clear Results");
	while (nResults > 0) {
	}
	wait(1);
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}

	run("Close All");
	while (nImages > 0) {
	}
	wait(1);
  	setBatchMode(false);
	
  	roiManager("reset");
  	if (roiManager("count") > 0)	{
	 roiManager("Deselect");
	 roiManager("Delete");
	}
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

function Update_FD(fontColors, nFDh) {
	N = lengthOf(fontColors);
	xOffset = 0.01 * nFDh;
	xStep = 0.185 * nFDh;
	xArrowGap = 0.005 * nFDh;
	xArrowLength = 0.04 * nFDh;
	Label = newArray("    Step 1  ","    Step 2  ","    Step 3  ","    Step 4  ","    Step 5  ","    End  ");
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
	LF=fromCharCode(0x0A);
	CR=fromCharCode(0x0D);
	Enter = CR+LF;

	shift=1;
    ctrl=2; 
    rightButton=4;
    alt=8;
    leftButton=16;
    insideROI = 32; // requires 1.42i or later

	descriptionText = newArray(6);
	descriptionText[0] = "Info regarding " + Enter + "Step 1";
	descriptionText[1] = "Info regarding " + Enter + "Step 2";
	descriptionText[2] = "Info regarding " + Enter + "Step 3";
	descriptionText[3] = "Info regarding " + Enter + "Step 4";
	descriptionText[4] = "Info regarding " + Enter + "Step 5";
	descriptionText[5] = "Info regarding termination" + Enter + "Step 6";

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
			if (boxIndex != lastBoxIndex) {
				lastBoxIndex = boxIndex;
				if (roiManager("count") > 11) {
					selectWindow("Flow Diagram");
					wait(20);
					roiManager("select",roiManager("count") - 1);
					roiManager("Delete");
					roiManager("Show All without labels");
					selectWindow("Flow Diagram");
					wait(20);
				}
				selectWindow("Flow Diagram");
				run("From ROI Manager");
				Add_Text(descriptionText[boxIndex],X[boxIndex] - Offset,160,10,"black");
				Overlay.show();
				run("To ROI Manager");
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
