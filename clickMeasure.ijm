macro "Main" {
	Initialize();
	ROIDiameter = getROIDiameter();
	XYZTC = loadPointROI();
	directory = measureROI(XYZTC, ROIDiameter);
	generateSaveROIs(XYZTC, ROIDiameter);
}

function Initialize() {
	Delay = 100;

  	showStatus("Basic initialization ...");
	print("\\Clear");
  	setBatchMode("exit and display");
  	setBatchMode(false);
  	wait(Delay);

  	showStatus("Checking open Image(s) ...");
  	nImages_ = nImages;
  	if (nImages_ > 1) {
		continueFlag = true;
		while (continueFlag) {
			waitForUser("Only one image can be analyzed. Please close the rest and click OK when ready.");
			wait(Delay);
		  	nImages_ = nImages;
		  	if (nImages_ == 1) {
				continueFlag = false;
		  	}
		}
  	} else if (nImages_ < 1) {
		continueFlag = true;
		while (continueFlag) {
			waitForUser("Please open an image and click OK when ready.");
			wait(Delay);
		  	nImages_ = nImages;
		  	if (nImages_ == 1) {
				continueFlag = false;
		  	}
		}
  	}
	run("Set Scale...", "distance=0 stack");
	run("Remove Overlay");
	run("Select None");
	wait(Delay);

  	showStatus("Selecting the Point tool ...");
	setTool("point");
	wait(Delay);
  	showStatus("Adjusting the Point tool ...");
	run("Point Tool...", "type=Dot color=Yellow size=Small add Stack");
	wait(Delay);
  	showStatus("Clearing selections ...");
	run("Select None");
	wait(Delay);
	
	
  	showStatus("Clearing ROI Manager ...");
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");
		while (roiManager("count") != 0)  {
		}
		wait(Delay);
	}

		
	showStatus("Receiving ROI centers ...");
	waitForUser("Please click (on the image) to choose ROI centers, and then click OK (here) when ready.");
	wait(Delay);

	showStatus("Clearing the Results Table ...");
	if (nResults > 0) {
		waitForUser("Please (save the Results Table, if needed, and) press OK to continue");
		wait(Delay);
	}
	run("Clear Results");
	wait(Delay);
}

function getROIDiameter() {
	defaultDiameter = 8;
	Dialog.create("");
	Dialog.addNumber("ROI Diameter:", defaultDiameter);
	Dialog.show();
	return round(parseFloat(Dialog.getNumber()));
}

function generateSaveROIs(XYZTC, ROIDiameter) {
	Delay = 10;
	ROIDiameterHalf = floor (ROIDiameter / 2);
	Stack.getDimensions(width, height, channels, slices, frames);
	nROIs = floor(lengthOf(XYZTC) / 5);
	for (cntr = 0; cntr < nROIs; cntr++) {
		x = XYZTC[cntr + 0 * nROIs];
		y = XYZTC[cntr + 1 * nROIs];
		slice = XYZTC[cntr + 2 * nROIs];
		frame = XYZTC[cntr + 3 * nROIs];
		channel = XYZTC[cntr + 4 * nROIs];
		Stack.setPosition(channel, slice, frame);
		run("Select None");
		wait(Delay);
		makeOval(x - ROIDiameterHalf, y - ROIDiameterHalf, ROIDiameter, ROIDiameter);
		run("Add Selection...");
		wait(Delay);
	}
	run("Select None");
	run("To ROI Manager");

  	saveROIFlag = true;
  	if (Stack.isHyperstack) {
  		if (!getBoolean("Saving ROIs is not recommended for hyperstacks. Save ROIs anyway?")) {
  			saveROIFlag = false;
  		}
  	}
  	if (saveROIFlag) {
		ROIFolder = getDirectory("Please choose the FOLDER to save ROIs");
		ROIFile = "CircularROI.zip";
		Dialog.create("File name selection");
		Dialog.addString("Saving ROIs as:", ROIFile);
		Dialog.show();
	  	ROIFile = Dialog.getString();	
		roiManager("Save", ROIFolder + ROIFile);
  	}
}

function measureROI(XYZTC, ROIDiameter) {
	ROIDiameterHalf = floor (ROIDiameter / 2);
	Stack.getDimensions(width, height, channels, slices, frames);
	nROIs = floor(lengthOf(XYZTC) / 5);
	for (cntr = 0; cntr < nROIs; cntr++) {
		x = XYZTC[cntr + 0 * nROIs];
		y = XYZTC[cntr + 1 * nROIs];
		slice = XYZTC[cntr + 2 * nROIs];
		frame = XYZTC[cntr + 3 * nROIs];
		channel = XYZTC[cntr + 4 * nROIs];
		Stack.setPosition(channel, slice, frame);
		run("Select None");
		wait(1);
		makeOval(x - ROIDiameterHalf, y - ROIDiameterHalf, ROIDiameter, ROIDiameter);
		run("Measure");
		while (cntr >= nResults) {
		}
		setResult("xROI", nResults - 1, XYZTC[cntr +  0 * nROIs]);
		setResult("yROI", nResults - 1, XYZTC[cntr +  1 * nROIs]);
		setResult("zROI", nResults - 1, XYZTC[cntr +  2 * nROIs]);
		setResult("tROI", nResults - 1, XYZTC[cntr +  3 * nROIs]);
		setResult("cROI", nResults - 1, XYZTC[cntr +  4 * nROIs]);
		setResult("DiamROI", nResults - 1, ROIDiameter);
	}
	updateResults();
	run("Select None");
	run("Remove Overlay");
	//setTool("rectangle");
	wait(10);
	saveAs("Results");
	wait(10);
	return File.directory;
}

function loadPointROI() {
	ROIDiameterHalf = floor (ROIDiameter / 2);

	dataTitle = getTitle();
	Stack.getDimensions(width, height, channels, slices, frames);

	nROIs = roiManager("count");
	roiManager("Deselect");
	while (roiManager("index") != -1) {
	}
	wait(10);
	XYZTC = newArray(5 * nROIs);
	selectWindow(dataTitle);
	while(getTitle != dataTitle) {
	}
	wait(10);
	for (cntr = 0; cntr < nROIs; cntr++) {
		roiManager("select", cntr);
		while (roiManager("index") != cntr) {
		}
		wait(10);
		Stack.getPosition(channel, slice, frame);
		getSelectionCoordinates(xpoints, ypoints);
		XYZTC[cntr + 0 * nROIs] = xpoints[0];
		XYZTC[cntr + 1 * nROIs] = ypoints[0];
		XYZTC[cntr + 2 * nROIs] = slice;
		XYZTC[cntr + 3 * nROIs] = frame;
		XYZTC[cntr + 4 * nROIs] = channel;
		roiManager("Deselect");
		while (roiManager("index") != -1) {
		}
	}
	roiManager("Deselect");
	roiManager("Delete");
	while (roiManager("count") != 0)  {
	}
	run("Remove Overlay");
	//setTool("rectangle");
	wait(10);
	return XYZTC;
}

