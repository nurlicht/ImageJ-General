// Program: cellPartition.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Works on a 2-channel image (or stack) and uses the information of nuclei (in the first channel) to estimate cell boundaries. The estimated cell boundaries will be added as a third channel to the composite image (or stack).

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	sampleFlag = decideDataType();
	Initialize(sampleFlag);
	wait(1);
	Stack.setDisplayMode("composite");
	run("16-bit");
	wait(1);
	stackID = getImageID();
	stackID = preProcessCurrentStack(stackID);
}

function preProcessCurrentStack(stackID) {
	selectImage(stackID);
	wait(1);
	imageTitle = getTitle();
	getDimensions(width, height, channels, slices, frames);

	for (cntr = 0; cntr < channels; cntr++) {
		wait(1);
		Stack.setChannel(1 + cntr);
		wait(1);
		run("Enhance Contrast", "saturated=0");
		wait(1);
	}
	wait(1);

	run("Split Channels");
	selectWindow("C1-"+imageTitle);
	run("Duplicate...", "duplicate");

	showStatus("Median Filtering");
	run("Median...", "radius=5 stack");

	twoThresholds = getTwoThresholds();
	setThreshold(twoThresholds[0], twoThresholds[1]);

	run("Make Binary", "method=Default background=Default black");
	run("Watershed", "stack");

	run("Voronoi", "stack");
	
	run("8-bit");
	rename("Voronoi.tif");
	run("Macro...", "code=[v = 255* v / v] stack");
	run("Macro...", "code=[v = 255 - v] stack");
	run("Set Measurements...", "area perimeter fit shape stack redirect=None decimal=3");	
	run("Analyze Particles...", "  show=[Overlay Outlines] display clear include summarize add in_situ stack");
	run("Macro...", "code=[v = 255 - v] stack");
	run("Grays");

	dilateFlag = false;
	if (dilateFlag) {
		run("Dilate");
		run("Dilate");
	}
	run("16-bit");
	roiManager("Show All without labels");

	wait(100);

	run("Merge Channels...", "c1=C1-"+imageTitle+" c2=C2-"+imageTitle+" c3=Voronoi.tif create");

	while(!isOpen(imageTitle)) {
	}
	wait(1);
	selectWindow(imageTitle);
	wait(10);
	Stack.getDimensions(width, height, nChannels_, nSlices_, nFrames_);
	wait(1);
	newStackID = 0;
	if (nSlices_ > 1) {
		 if (nFrames_ == 1) {
		 	nFrames_ = nSlices_;
		 	nSlices_ = 1;
		 } else {
		 	print("Hyperstack not allowed: nslices = " + nSlices_ + ", nFrames = " + nFrames_);
		 	newStackID = NaN;
		 }
	}
	run("Properties...", "slices="+nSlices_+" frames="+nFrames_);
	wait(1);
	Stack.setDisplayMode("composite");
	wait(1);
	Stack.setChannel(2);
	wait(1);
	if (!isNaN(newStackID)) {
		wait(1);
		newStackID = getImageID();
		wait(1);
	}
	return newStackID;
}

function Initialize(sampleFlag) {
  	print("\\Clear");
	wait(1);

  	roiManager("reset");
  	wait(100);
	//run("Collect Garbage");wait(10);

	setBatchMode("exit and display");
	wait(100);
	setBatchMode(false);
	wait(1);
	if (sampleFlag) {
		run("Close All");
		wait(1);
		list = getList("window.titles");
		listLength = list.length;
		if (listLength > 0) {
			for (i = 0; i < listLength; i++) {
				print("Window #" + (i + 1) + " " + list[i] + " (out of " + listLength + " windows)");
				if (endsWith(list[i],"Results")) {
					wait(1);
					selectWindow(list[i]);
					wait(1);
					run("Close");
					wait(1);
					print("Window " + list[i] + " was closed.");
				}
			}	
		}
		simulateFlag = false;
		if (simulateFlag) {
			nCells = 15;
			nX = 500;
			synthesizeCells(nCells, nX);
		} else {
			imageTitle = "twoChannelCells.tif";
			imageURLFolder = "http://www.zmbh.uni-heidelberg.de/Central_Services/Imaging_Facility/ijMacrosImages/";
			open(imageURLFolder + imageTitle);
			while (!isOpen(imageTitle)) {
			}
		}
			wait(1);
	} else {
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
	}
	run("Clear Results");
	updateResults();
	run("ROI Manager...");
	wait(1);
	tableFileExtension = "csv";
	run("Input/Output...", "jpeg=85 gif=-1 file="+tableFileExtension+" copy_column save_column");
}

function getTwoThresholds() {
	Delay = 10;
	run("Threshold...");
	setAutoThreshold("Default dark stack");	
	wait(Delay);

	getStatistics(area, mean, min, max, std, histogram);
	min_ = min + 0.1 * (max - min);
	
	twoThresholds = newArray(min_, max);

	dialogFlag = false;
	if (dialogFlag) {
		waitForUser("Please scan the threshold level and write down the Lower and Upper bounds. Press OK when ready.");
		wait(Delay);

		Dialog.create("Threshold Levels");
		Dialog.addNumber("Lower Threshold Level", twoThresholds[0]);
		Dialog.addNumber("Upper Threshold Level", twoThresholds[1]);
		Dialog.show();
	  	twoThresholds[0] = parseFloat(Dialog.getNumber());	
	  	twoThresholds[1] = parseFloat(Dialog.getNumber());
	  	if (twoThresholds[0] > twoThresholds[1]) {
			dummy_1 = twoThresholds[1];
			twoThresholds[1] = twoThresholds[0];
			twoThresholds[0] = dummy_1;
			waitForUser("The two threshold levels of " twoThresholds[0] + " and " + twoThresholds[1] " were swapped.");
			wait(Delay);
	  	}
	}
  	resetThreshold();
	wait(Delay);
	return twoThresholds;
}

function decideDataType() {
	items = newArray("Use sample data", "Load my own data");
	Dialog.create("Partitioning cells");
	Dialog.addRadioButtonGroup("Source of data", items, 2, 1, items[0]);
	Dialog.show();
	if (Dialog.getRadioButton() == items[0]) {
		sampleFlag = true;
	} else {
		sampleFlag = false;
	}
	return sampleFlag;
}

function synthesizeCells(nCells, nX) {
	xMin = 0;
	xMax = nX - 1;
	xHalf = floor(nX / 2);

	yMin = xMin;
	yMax = xMax;
	yHalf = xHalf;

	x = xHalf;
	y = yHalf;

	xDiameter = 60;
	yDiameter = 30;
	xDiameterHalf = floor(xDiameter / 2);
	yDiameterHalf = floor(yDiameter / 2);
	title = "SynthesizedCells";
	newImage(title, "8-bit black", nX, nX, 2);

	makeOval(x - xDiameterHalf, y - yDiameterHalf,xDiameter, yDiameter);
	Overlay.addSelection("", 0 ,"#" + toHex(0xffffff));
	
	for (cntr = 1; cntr < nCells; cntr++) {
		x_ = floor(xMax * random); 
		x_ = maxOf(x_, xMin);
		x_ = minOf(x_, xMax);
		x = x_;

		y_ = floor(yMax * random); 
		y_ = maxOf(y_, yMin);
		y_ = minOf(y_, yMax);
		y = y_;

		wait(1);
		makeOval(x - xDiameterHalf, y - yDiameterHalf,xDiameter, yDiameter);
		run("Rotate...", "  angle=" + (45 * random));
		Overlay.addSelection("", 0 ,"#" + toHex(0xffffff));
		
	}
	Overlay.show();
	run("Select None");
	run("Flatten","stack");
	wait(1);
	run("8-bit");
	wait(1);
	Stack.setChannel(1);
	wait(1);
	run("Red");	
	Stack.setChannel(2);
	wait(1);
	run("Green");	
	wait(1);

	run("Make Composite", "display=Composite");	

	//run("Set... ", "zoom=400 x=" + getWidth + " y=" + getHeight);
	return true;
}
