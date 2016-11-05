// Program: browsePlots.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Loads and plots a set of measurement files together as a 2D image. Furthermore, by browsing the ROI Manager, one can see individual 1D plots. The test data shows a series of kinetics profiles corresponding to a second-order system with different levels of feedback. This classical control problem has found more biological relevance recently.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	simulateFlag = decideDataType();
	imageTitle2D = plotAll(simulateFlag);
	browsePlots(simulateFlag, imageTitle2D);
}

function Initialize() {
	setBatchMode("exit and display");
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

function browsePlots(simulateFlag, imageTitle2D) {
	selectWindow_(imageTitle2D);
 	nData = getWidth;
 	nFiles = getHeight;

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
	while(contFlag) {
		roiIndex = roiManager("index");
		if (roiIndex != -1) {
			if (shownPlot_ == shownPlot_) {
				closeWindow_(shownPlot_);
			}
			selectWindow_(imageTitle2D);
			for (cntrD = 0; cntrD < nData; cntrD++) {
				v[cntrD] = getPixel(cntrD,roiIndex);
			}
			run("Select None");
	 		if (!simulateFlag) {
				Plot.create(fileList[roiIndex], "Time", "Intensity (given Channel)", Time, v);
	 		} else {
				Plot.create("Simulated file " + roiIndex, "Time", "Intensity (given Channel)", Time, v);
	 		}
			Plot.setLimits(TMin, TMax, vMin, vMax);
			Plot.show;
			setLocation(0,0);
			shownPlot_ = getTitle();
			selectWindow("ROI Manager");
		}
		if (roiManager("count") == 0) {
			contFlag = false;
		}
	}
	varArgOut = newArray("1");
	return varArgOut;
}

function plotAll(simulateFlag) {
 	if (!simulateFlag) {
 		filePath = getDirectory("Choose the FOLDER of (synchronized) Measurement files (all starting with MEAS)");
		fileListOriginal = getFileList(filePath);
		nFilesOriginal = lengthOf(fileListOriginal);
		fileList = newArray(nFilesOriginal);
		nFiles = 0;
		for (cntr = 0; cntr < nFilesOriginal; cntr++) {
			if (startsWith(fileListOriginal[cntr],"Meas")) {
				fileList[nFiles++] = fileListOriginal[cntr];
			}
		}
		fileList = Array.slice(fileList,0,nFiles);
		run("Clear Results");
		run("Results... ","open="+"["+filePath+fileList[0]+"]");
		nData = nResults;
		run("Clear Results");
 	} else {
 		nFiles = 50;
 		nData =80;
 	}

	nTotal = nData * nFiles;
	imageParams = newArray();
	imageTitle2D = "All 1D profiles";
	newImage(imageTitle2D, "32-bit", nData, nFiles, 1);
	run("Remove Overlay");
	for (cntr = 0; cntr < nFiles; cntr++) {
	 	if (!simulateFlag) {
			run("Clear Results");
			run("Results... ","open="+"["+filePath+fileList[cntr]+"]");
	 	}
		for (cntrD = 0; cntrD < nData; cntrD++) {
		 	if (!simulateFlag) {
				data_ = getResult("Measurement", cntrD);
		 	} else {
				//data_ = sqrt(cntr + 1) * abs(cos(2 * PI * sqrt(cntr + 1) * cntrD / (4 * nFiles)));

				//Root-locus simulation of a simple second order system 
				k = 3 * pow(cntr / (nFiles), 2);
				t = 20 * (1 + cntrD) / (1 + nData);
				Delta = pow(k, 2) - 1;
				if (Delta > 0) {
					Delta_ = sqrt(Delta);
					S = newArray(- k + Delta_, - k - Delta_);
					A = newArray(S[1] / (S[1] - S[0]), S[0] / (S[0] - S[1]));
					data_ = A[0] * exp(S[0] * t) + A[1] * exp(S[1] * t);
				} else if (Delta == 0) {
					data_ = exp(- k * t) * (1 - t);
				} else if (Delta < 0) {
					Alpha = - k;
					Beta = sqrt(- Delta);
					data_ = exp(Alpha * t) * ((Alpha / Beta) * sin(Beta * t) + cos(Beta * t));
				}
		 	}
			setPixel(cntrD, cntr, data_);
		}
	}

	getRawStatistics(nPixels, mean, min, max, std, histogram);
	for (cntr = 0; cntr < nFiles; cntr++) {
		for (cntrD = 0; cntrD < nData; cntrD++) {
			setPixel(cntrD,cntr, (getPixel(cntrD,cntr) - min) / (max - min));
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
	//run("Calibration Bar...", "location=[Upper Right] fill=White label=[Dark Gray] number=8 decimal=2 font=9 zoom=0.25 overlay");
	run("Set... ", "zoom=600 x=99 y=16");
	if (simulateFlag) {
		setFont("Serif", 4, "antialiased");
		setColor(255, 255, 255);
		Overlay.drawString("Effect of feedback on kinetics", 0.2 * getWidth, 1 * getHeight);
		Overlay.show;
		wait(1);
	}	
	
	return imageTitle2D;
}

function decideDataType() {
	items = newArray("Simulate data", "Load data");
	Dialog.create("Visualization of multiple measurements");
	Dialog.addRadioButtonGroup("Source of data", items, 2, 1, items[0]);
	Dialog.show();
	if (Dialog.getRadioButton() == items[0]) {
		simulateFlag = true;
	} else {
		simulateFlag = false;
	}
	return simulateFlag;
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle != imageTitle) {
	}
	return getTitle;
}

function closeWindow_(imageTitle) {
	close(imageTitle);
	while (isOpen(imageTitle)) {
	}
	//wait(1);
	return true;
}
