// Program: transportRegime.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Plots the average Mean Square Distance (MSD) vs. Lag Time of a given track. The curvature and the slope of this curve are important signatures of the transport regime.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	simulateFlag = decideDataType();
	if (simulateFlag) {
		nPoints = 100;
		nX = 500;
		XYT = synthesizePath(nPoints, nX);
		x = Array.slice(XYT, 0 * nPoints, 1 * nPoints);
		y = Array.slice(XYT, 1 * nPoints, 2 * nPoints);
		Time = Array.slice(XYT, 2 * nPoints, 3 * nPoints);
	} else {
		// Load the arrays "x", "y", and "Time"
		waitForUser("Please edit the code to introduce the tracking data");
		wait(1);
		return 0;
	}
	correlationAnalysis(x, y, Time);
}

function Initialize() {
  	setBatchMode(false);
	print("\\Clear");
	if (nImages > 0) {
		run("Close All");
		while (nImages > 0) {
		}
		wait(1);
	}
	if (nResults > 0) {
		run("Clear Results");
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	wait(1);
}

function synthesizePath(nPoints, nX) {
	x = newArray(nPoints);
	y = newArray(nPoints);
	t = newArray(nPoints);

	xMin = 0;
	xMax = nX - 1;
	x[0] = floor(nX / 2);
	dx = maxOf(1, floor(nX * 0.04));

	yMin = xMin;
	yMax = xMax;
	y[0] = x[0];
	dy = dx;

	t[0] = 0;

	xDiameter = 10;
	yDiameter = xDiameter;
	xDiameterHalf = floor(xDiameter / 2);
	yDiameterHalf = floor(yDiameter / 2);
	newImage("synthesized Tracks", "8-bit", nX, nX, 1);

	makeOval(x[0] - xDiameterHalf, y[0] - yDiameterHalf,xDiameter, yDiameter);
	Overlay.addSelection("", 0 ,"#" + toHex(0xff0000));
	
	for (cntr = 1; cntr < nPoints; cntr++) {
		x_ = x[cntr - 1] + floor(dx * 2 * (random - 0.5));
		x_ = maxOf(x_, xMin);
		x_ = minOf(x_, xMax);
		x[cntr] = x_;

		y_ = y[cntr - 1] + floor(dy * 2 * (random - 0.5)); 
		y_ = maxOf(y_, yMin);
		y_ = minOf(y_, yMax);
		y[cntr] = y_;

		t[cntr] = cntr;

		makeOval(x[cntr] - xDiameterHalf, y[cntr] - yDiameterHalf,xDiameter, yDiameter);
		fraction = round(255 * cntr / (nPoints - 1));
		color = toHex(fraction * (- 0x010000 + 0x000001) + 0xff0000);
		nColor = lengthOf(color);
		if (nColor < 6) {
			for (cntr2 = 0; cntr2 < (6 - nColor); cntr2++) {
				color = "0" + color;
			}
		}
		Overlay.addSelection("", 0, "#" + color);
	}
	Overlay.show();
	run("Select None");
	//run("Set... ", "zoom=400 x=" + getWidth + " y=" + getHeight);
	XY = Array.concat(x, y);
	XYT = Array.concat(XY, t);
	return XYT;
}

function correlationAnalysis(x,y,t) {
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
	Plot.create("Correlation analysis of the track (diffusion regime estimation)",
				"Lag Time (" + fromCharCode(0x0394) + "t)", 
				"Mean Square Distance (d" + fromCharCode(0x00B2) + ")",
				lagVariable, corrFunction);
	Plot.setLimits(LagMin, LagMax, corrMin, corrMax);	
	Plot.show;
	wait(1000);
}

function decideDataType() {
	items = newArray("Simulate data", "Load data");
	Dialog.create("Correlation Analysis of a track");
	Dialog.addRadioButtonGroup("Source of data", items, 2, 1, items[0]);
	Dialog.addHelp("http://www.nature.com/mt/journal/v19/n7/fig_tab/mt2011102f2.html#figure-title");
	Dialog.show();
	if (Dialog.getRadioButton() == items[0]) {
		simulateFlag = true;
	} else {
		simulateFlag = false;
	}
	return simulateFlag;
}
