macro "Main" {
	Initialize();
	allParams = initializeAllParams();
	allParams = setMainFolder(allParams);
	allParams = setSeriesOrSubfoldersNames(allParams);
	if (isMainFolderInvalid(allParams)) return;
	
	allParams = setDetectionParams(allParams);
	nSeries = getNSeries(allParams);
	stackFlag = getStackFlag(allParams);
	if (stackFlag) {
		seriesCntr = 0;
		allParams = setSeriesPath(allParams, seriesCntr);
		allParams = openCurrentSeries(allParams);
		allParams = setTubeCoordinates(allParams);
		nTubes = getNTubes(allParams);
		allParams = closeCurrentSeries(allParams);
		for (seriesCntr = 0; seriesCntr < nSeries; seriesCntr++) {
			allParams = setSeriesPath(allParams, seriesCntr);
			allParams = openCurrentSeries(allParams);
			allParams = subtractBackground(allParams);
			allParams = setSeriesMinMax(allParams);
			for (tubeCntr = 0; tubeCntr < nTubes; tubeCntr++) {
				allParams = duplicateFullImage(allParams, tubeCntr);
				allParams = extractCurrentTube(allParams);
				allParams = setFullContrast(allParams);
				allParams = setThreshold_(allParams);
				allParams = runAnalyzeParticles(allParams);
				allParams = saveSummaryTable(allParams);
				allParams = copyRefinedXYToResults(allParams);
				allParams = saveFinalTables(allParams);
				allParams = closeSummaryTable(allParams);
				allParams = closeCurrentTube(allParams);
			}
			allParams = closeCurrentSeries(allParams);
		}
	} else {
		//"Similar" code with another loop over frames in each series
	}
}

function copyRefinedXYToResults(allParams) {
	tubeTitle = "" + allParams[24];
	roiManager("Show All without labels");
	if (roiManager("count") > 0) {
		XYT = getROICoordinates(tubeTitle);
		nFrames = getNFrames(tubeTitle);
		XY = refineObjects(XYT, nFrames);
		copyXYToResults(XY);
	}
	return allParams;
}

function saveFinalTables(allParams) {
	mainFolder = "" + allParams[1];
	tableTitle = "" + allParams[26];

	selectWindow("Results");
	wait(100);
	saveAs("results", mainFolder + tableTitle + "_Final");

	if (roiManager("count") > 0) {
		makeResultsMatlabCompatible();
	}
	
	selectWindow("Results");
	wait(100);
	saveAs("results", mainFolder + tableTitle + "_Final_MatlabCompatible");
	
	return allParams;
}

function closeSummaryTable(allParams) {
	tableTitle = "" + allParams[26];
	selectWindow(tableTitle);
	wait(100);
	run("Close");
	while (isOpen(tableTitle)) {
	}
	wait(1);
	allParams[26] = "";
	return allParams;
}

function saveSummaryTable(allParams) {
	mainFolder = "" + allParams[1];
	tubeTitle = "" + allParams[24];
	tableTitle = "Summary of " + tubeTitle;
	selectWindow(tableTitle);
	wait(100);
	saveAs("results", mainFolder + tableTitle);
	allParams[26] = "" + tableTitle;
	return allParams;
}

function runAnalyzeParticles(allParams) {
	minAreaParticle = "" + allParams[10];
	maxAreaParticle = "" + allParams[11];
	minCircParticle = "" + allParams[12];
	maxCircParticle = "" + allParams[13];
	tubeTitle = "" + allParams[24];
	selectWindow_(tubeTitle);
	run("Analyze Particles...", "size=" + minAreaParticle + "-" + maxAreaParticle + " circularity=" +
			minCircParticle + "-" + maxCircParticle + " show=Overlay display exclude clear include " +
			"summarize add stack");
	return allParams;
}

function setThreshold_(allParams) {
	threshold_1 = parseFloat(allParams[6]);
	tubeTitle = "" + allParams[24];
	selectWindow_(tubeTitle);
	setThreshold(threshold_1, 255);
	return allParams;
}

function setFullContrast(allParams) {
	min = parseFloat(allParams[19]);
	max = parseFloat(allParams[20]);
	tubeTitle = "" + allParams[24];
	selectWindow_(tubeTitle);
	run("Macro...", "code=[v = 255 * (" + max + " - v) / (" + max + " - " + min + ")] stack");
	return allParams;
}

function duplicateFullImage(allParams, tubeCntr) {
	currentTitle = "" + allParams[14];
	tubeTitle = currentTitle + "_Tube_" + tubeCntr;

	while (!isOpen(currentTitle)) {
	}

	selectWindow_(currentTitle);
	run("Remove Overlay");
	selectWindow_(currentTitle);
	run("Select None");
	selectWindow_(currentTitle);
	nImages_ = nImages;
	run("Duplicate...", "title=[" + tubeTitle + "] duplicate");
	while (nImages_ == nImages) {
	}
	while (!isOpen(tubeTitle)) {
	}

	selectWindow_(tubeTitle);
	run("Remove Overlay");
	selectWindow_(tubeTitle);
	run("Select None");
	
	allParams[24] = "" + tubeTitle;
	allParams[25] = "" + tubeCntr;
	return allParams;
}

function extractCurrentTube(allParams) {
	tubeTitle = "" + allParams[24];
	tubeCntr = parseInt(allParams[25]);
	tubeCoordinates = getTubeCoordinates(allParams);
	x = tubeCoordinates[4 * tubeCntr + 0];
	y = tubeCoordinates[4 * tubeCntr + 1];
	tubeWidth = tubeCoordinates[4 * tubeCntr + 2];
	tubeHeight = tubeCoordinates[4 * tubeCntr + 3];
	selectWindow_(tubeTitle);
	makeRectangle(x, y, tubeWidth, tubeHeight);
	selectWindow_(tubeTitle);
	run("Crop");
	while(getWidth != tubeWidth) {
		selectWindow_(tubeTitle);
	}
	allParams[17] = "" + tubeWidth;
	allParams[18] = "" + tubeHeight;
	selectWindow_(tubeTitle);
	return allParams;
}

function setSeriesMinMax(allParams) {
	currentTitle = "" + allParams[14];
	selectWindow_(currentTitle);
	getMinAndMax(min, max);
	allParams[19] = "" + min;
	allParams[20] = "" + max;
	return allParams;
}

function subtractBackground(allParams) {
	currentTitle = getCurrentTitle(allParams);
	selectWindow_(currentTitle);
	nImages_ = nImages;
	run("Z Project...", "projection=[Average Intensity]");
	while (nImages_ == nImages) {
	}
	avgTitle = "AVG_" + currentTitle;
	nImages_ = nImages;
	imageCalculator("Subtract create 32-bit stack", currentTitle, avgTitle);
	while (nImages_ == nImages) {
	}
	close_(avgTitle);
	close_(currentTitle);
	rename_(currentTitle);
	run("8-bit");
	while(bitDepth != 8) {
	}
	return allParams;
}

function getNTubes(allParams) {
	return parseInt(allParams[16]);	
}

function getCurrentTitle(allParams) {
	return "" + allParams[14];
}

function getTubeCoordinates(allParams) {
	tubeCoordinatesString = "" + allParams[15];
	print("tubeCoordinatesString = " + tubeCoordinatesString);
	tubeCoordinates = string2Array(tubeCoordinatesString);
	print("tubeCoordinates Array:");Array.print(tubeCoordinates);
	
	nTubeCoordinates = lengthOf(tubeCoordinates);
	tubeCoordinatesNum = newArray(nTubeCoordinates);
	for (cntr = 0; cntr < nTubeCoordinates; cntr++) {
		tubeCoordinatesNum[cntr] = parseFloat(tubeCoordinates[cntr]);
	}
	print("tubeCoordinatesNum Array:");Array.print(tubeCoordinatesNum);
	return tubeCoordinatesNum;
}

function setTubeCoordinates(allParams) {
	//tubeCoordinates = setTubeCoordinatesAutomatically(currentTitle);
	//nTubes = lengthOf(tubeCoordinates) - 1;

	//tubeCoordinates = setTubeCoordinatesManually(currentTitle);
	//nTubes = lengthOf(tubeCoordinates) / 4;

	
	seriesTitle = getCurrentTitle(allParams);
	tubeCoordinates = setTubeCoordinatesManually(seriesTitle);
	nTubes = lengthOf(tubeCoordinates) / 4;
	allParams[15] = "" + array2String(tubeCoordinates);
	allParams[16] = "" + nTubes;
	return allParams;
}

function closeCurrentTube(allParams) {
	tubeTitle = "" + allParams[24];
	if (isOpen(tubeTitle)) {
		close_(tubeTitle);
	}
	tubeTitle = "";
	allParams[24] = "" + tubeTitle;
	return allParams;
}

function closeCurrentSeries(allParams) {
	currentTitle = "" + allParams[14];
	if (isOpen(currentTitle)) {
		close_(currentTitle);
	}
	currentTitle = "";
	seriesPath = "";
	allParams[14] = "" + currentTitle;
	allParams[21] = "" + seriesPath;
	return allParams;
}

function openCurrentSeries(allParams) {
	seriesPath = "" + allParams[21];
	currentTitle = open_(seriesPath);
	selectWindow_(currentTitle);
	run("Remove Overlay");
	selectWindow_(currentTitle);
	run("Select None");
	allParams[14] = "" + currentTitle;
	return allParams;
}

function getNSeries(allParams) {
	return parseInt(allParams[3]);
}

function getStackFlag(allParams) {
	return parseInt(allParams[0]);
}

function setDetectionParams(allParams) {
	threshold_1 = 134;
	tubeY = 36;
	minSizeBPF = 4;
	maxSizeBPF = 40;
	minAreaParticle = 40;
	maxAreaParticle = 1500;
	minCircParticle = 0.20;
	maxCircParticle = 1.00;
	
	Dialog.create("Spot detection parameters");
	Dialog.addMessage("Pre-processing parameters");
	Dialog.addNumber("Threshold intensity (in inverted image)", threshold_1);
	Dialog.addNumber("Upper height of tube to be discarded (in pixels)", tubeY);
	//Dialog.addNumber("Minimum area of particle for filtering (pixels^2)", minSizeBPF);
	//Dialog.addNumber("Maximum area of particle for filtering (pixels^2)", maxSizeBPF);
	Dialog.addMessage("Particle detection");
	Dialog.addNumber("Minimum area of particle for detection (pixels^2)", minAreaParticle);
	Dialog.addNumber("Maximum area of particle for detection (pixels^2)", maxAreaParticle);
	Dialog.addNumber("Minimum circularity of particle for detection (pixels^2)", minCircParticle);
	Dialog.addNumber("Maximum circularity of particle for detection (pixels^2)", maxCircParticle);
	Dialog.show;
	threshold_1 = Dialog.getNumber();	
	tubeY = Dialog.getNumber();
	//minSizeBPF = Dialog.getNumber();
	//maxSizeBPF = Dialog.getNumber();
	minAreaParticle = Dialog.getNumber();
	maxAreaParticle = Dialog.getNumber();
	minCircParticle = Dialog.getNumber();
	maxCircParticle = Dialog.getNumber();

	allParams[6] = "" + threshold_1;		// threshold_1
	allParams[7] = "" + tubeY;				// tubeY
	allParams[8] = "" + 0;					// minSizeBPF
	allParams[9] = "" + 0;					// maxSizeBPF
	allParams[10] = "" + minAreaParticle;	// minAreaParticle
	allParams[11] = "" + maxAreaParticle;	// maxAreaParticle
	allParams[12] = "" + minCircParticle;	// minCircParticle
	allParams[13] = "" + maxCircParticle;	// maxCircParticle

	return allParams;
}

function isMainFolderInvalid(allParams) {
	mainFolder = "" + getMainFolder(allParams);
	return (mainFolder == "");
}

function getMainFolder(allParams) {
	mainFolder = "" + allParams[1];
	return mainFolder;
}

function setMainFolder(allParams) {
	mainFolder = getDirectory("Please choose the directory (including images)");
	allParams[1] = "" + mainFolder;
	return allParams;
}

function setSeriesOrSubfoldersNames(allParams) {
	mainFolder = allParams[1];
	entitiesList = getFileList(mainFolder);
	nEntities = lengthOf(entitiesList);
	nFolders = 0;
	nFiles = 0;
	for (cntr = 0; cntr < nEntities; cntr++) {
		currentEntitty = entitiesList[cntr];
		if (substring(currentEntitty, lengthOf(currentEntitty) - 1) == "/") {
			print("Subdirectory " + (++nFolders) + ": " + currentEntitty);
		} else {
			print("File " + (++nFiles) + ": " + currentEntitty);
		}
	}
	if (nFolders > 0) {
		if (nFiles == 0) {
			print("" + nFolders + " image series (as folders) were detected.");
			allParams[0] = "" + 0;
			allParams[2] = "" + array2String(entitiesList);
			allParams[3] = "" + nFolders;
		} else {
			print("Error: EITHER image files OR image folders! " + nFolders + " folders and " + nFiles + " files were detected.");
			waitForUser("Error: EITHER image files OR image folders! " + nFolders + " folders and " + nFiles + " files were detected.");
			wait(1);
			allParams[1] = "" + "";
		}
	} else {
		if (nFiles == 0) {
			print("Error: The main folder is empty!");
			waitForUser("Error: The main folder is empty!");
			wait(1);
			allParams[1] = "" + "";
		} else {
			print("" + nFiles + " image series (as stacks) were detected.");
			allParams[0] = "" + 1;
			allParams[2] = "" + array2String(entitiesList);
			allParams[3] = "" + nFiles;
		}
	}
	return allParams;
}

function setSeriesPath(allParams, seriesCntr) {
	allSeriesOrSubfoldersString = allParams[2];
	allSeriesOrSubfoldersArray = string2Array(allSeriesOrSubfoldersString);
	seriesName = allSeriesOrSubfoldersArray[seriesCntr];
	seriesPath = "" + getMainFolder(allParams) + seriesName;
	allParams[21] = seriesPath;
	allParams[23] = seriesName;
	print("\n\nCurrent Series: " + seriesName);
	return allParams;
}

function initializeAllParams() {
	nAllParams = 40;
	allParams = newArray(nAllParams);

	allParams[0] = "" + 1;					// stackFlag
	allParams[1] = "" + "";					// mainFolder
	allParams[2] = "" + "";					// allSeriesOrSubfoldersString
	allParams[3] = "" + 1;					// nSeries
	allParams[4] = "" + 1;					// currentNFrames
	allParams[5] = "" + 1;					// currentFrameIndex
	allParams[6] = "" + 0;					// threshold_1
	allParams[7] = "" + 0;					// tubeY
	allParams[8] = "" + 0;					// minSizeBPF
	allParams[9] = "" + 0;					// maxSizeBPF
	allParams[10] = "" + 1;					// minAreaParticle
	allParams[11] = "" + "inf";				// maxAreaParticle
	allParams[12] = "" + 0;					// minCircParticle
	allParams[13] = "" + 1.00;				// maxCircParticle
	allParams[14] = "" + "";				// currentImageTitle
	allParams[15] = "" + "";				// tubeCoordinatesString
	allParams[16] = "" + 0;					// nTubes
	allParams[17] = "" + 0;					// tubeWidth		
	allParams[18] = "" + 0;					// tubeHeight
	allParams[19] = "" + 0;					// currentImageMin
	allParams[20] = "" + 0;					// currentImageMax
	allParams[21] = "" + "";				// currentImagePath
	allParams[22] = "" + "";				// currentSubfolder
	allParams[23] = "" + "";				// currentImageFile
	allParams[24] = "" + "";				// currentTubeTitle
	allParams[25] = "" + "";				// currentTubeCntr
	allParams[26] = "" + "";				// tableTitle
	//allParams[] = "" + ;
	//allParams[] = "" + ;
	

	return allParams;
}

function makeResultsMatlabCompatible() {
	nResults_ = nResults;
	for (cntr = 0; cntr < nResults_; cntr++) {
		setResult("T", cntr, getResult("T", cntr) * 1000 + floor(100 * random));
		temp = getResult("X", cntr);
		if (temp != temp) {
			setResult("X", cntr, -1);
		}
		temp = getResult("Y", cntr);
		if (temp != temp) {
			setResult("Y", cntr, -1);
		}
		setResult("Z", cntr, random);
		setResult("X2", cntr, getResult("X", cntr));
		setResult("Y2", cntr, getResult("Y", cntr));
		setResult("Z2", cntr, getResult("Z", cntr));
		setResult("X3", cntr, getResult("X", cntr));
		setResult("Y3", cntr, getResult("Y", cntr));
		setResult("Z3", cntr, getResult("Z", cntr));
	}
	updateResults();
	wait(100);
}

function setTubeCoordinatesManually(imageTitle) {
	nTubes = 12;

	doubleCheckNTubesFlag = true;
	if (doubleCheckNTubesFlag) {
		Dialog.create("Tube parameters");
		Dialog.addNumber("Number of Tubes", nTubes);
		Dialog.show;
		nTubes = Dialog.getNumber();	
	}

	tubeCoordinates = newArray(nTubes * 4);
	for (cntr = 0; cntr < nTubes; cntr++) {
		waitForUser("Please select Tube #" + (cntr + 1) + " and then press OK.");
		wait(1);
		getSelectionBounds(x, y, width, height);
		tubeCoordinates[4 * cntr + 0] = x;
		tubeCoordinates[4 * cntr + 1] = y;
		tubeCoordinates[4 * cntr + 2] = width;
		tubeCoordinates[4 * cntr + 3] = height;
	}
	run("Select None");

	return tubeCoordinates;
}

function setTubeCoordinatesAutomatically(imageTitle) {
	minThreshold = 60;
	nMinima = 12;
	nMinimaP1 = nMinima + 1;

	selectWindow_(imageTitle);
	nImages_ = nImages;
	plotProfileTitle = "Plot_Profile";
	run("Select All");
	run("Plot Profile");
	while(nImages_ == nImages) {
	}
	rename(plotProfileTitle);
	while(!isOpen(plotProfileTitle)) {
	}
	Plot.getValues(x, y);
	minTolerance = 10;
	changeValue = 0.05;
	continueFlag = true;
	while (continueFlag) {
		minLocs = Array.findMinima(y, minTolerance);
		Array.sort(minLocs);
		nMinLocs = lengthOf(minLocs);
		if (nMinLocs > nMinimaP1) {
			minTolerance *= (1 + changeValue);
		} else if (nMinLocs < nMinimaP1) {
			minTolerance /= (1 + changeValue);
		} else {
			continueFlag = false;
		}
		//print("nMinLocs = " + nMinLocs);
	}
	close_(plotProfileTitle);
	selectWindow_(imageTitle);
	run("Select None");
	return minLocs;
}

function getSortedIndex(inArray) {
	showStatus("Sorting the array ...");
	N = lengthOf(inArray);
	if (N == 0) {
		print("Null array fed to sortIndex function.");
	}
	N_1 = N - 1;
	sortedIndex = Array_getSequence(N);
	for (cntr1 = 0; cntr1 < N_1; cntr1++) {
		for (cntr2 = (cntr1 + 1); cntr2 < N; cntr2++) {
			if (inArray[sortedIndex[cntr1]] > inArray[sortedIndex[cntr2]]) {
				temp = sortedIndex[cntr1];
				sortedIndex[cntr1] = sortedIndex[cntr2];
				sortedIndex[cntr2] = temp;
			}
		}
		showProgress(cntr1, N_1);
	}
	showStatus("");
	return sortedIndex;
}

function copyXYToResults(XY) {
	nFrames = lengthOf(XY) / 2;
	run("Clear Results");
	updateResults();
	wait(10);
	for (cntr = 0; cntr < nFrames; cntr++) {
		setResult("T", cntr, cntr + 1);
		setResult("X", cntr, XY[cntr]);
		setResult("Y", cntr, XY[cntr + nFrames]);
	}
	updateResults();
	wait(10);
}

function refineObjects(XYT, nFrames) {
	nFrames_2 = nFrames * 2;
	XY = newArray(nFrames_2);
	for (cntr = 0; cntr < nFrames_2; cntr++) {
		XY[cntr] = NaN;
	}
	currentROIIndex = 0;
	nROIs = lengthOf(XYT) / 3;
	nROIs_1 = nROIs - 1;
	for (xyCntr = 0; xyCntr < nFrames; xyCntr++) {
		currentXYFrame = xyCntr + 1;
		currentROIFrame = XYT[currentROIIndex + 2 * nROIs];
		if (currentXYFrame == currentROIFrame) {
			acceptROIFlag = false;
			if (currentROIIndex == nROIs_1) {
				acceptROIFlag = true;
			} else if (currentROIIndex < nROIs_1) {
				nextROIFrame = XYT[currentROIIndex + 1 + 2 * nROIs];
				if (nextROIFrame >  currentROIFrame) {
					if (currentROIIndex == 0) {
						acceptROIFlag = true;
					} else {
						previousROIFrame = XYT[currentROIIndex - 1 + 2 * nROIs];
						if (previousROIFrame <  currentROIFrame) {
							acceptROIFlag = true;
						}
					}
				} else {
					continueFlag = true;
					while(continueFlag) {
						if (currentROIIndex < (nROIs_1 - 1)) {
							currentROIIndex++;
							currentROIFrame = XYT[currentROIIndex + 2 * nROIs];
							nextROIFrame = XYT[currentROIIndex + 1 + 2 * nROIs];
							continueFlag = (nextROIFrame ==  currentROIFrame);
						} else {
							continueFlag = false;
						}
					}
				}
			}
			if (acceptROIFlag) {
				XY[xyCntr] = XYT[currentROIIndex];
				XY[xyCntr + nFrames] = XYT[currentROIIndex + nROIs];
			}
			currentROIIndex++;
		}
	}
	return XY;
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while(getTitle() != imageTitle) {
	}
	wait(1);
}

function getNFrames(imageTitle) {
	selectWindow_(imageTitle);
	return getSliceNumber();
}

function getROICoordinates(imageTitle) {
	selectWindow_(imageTitle);

	roiManager("Deselect");
	while (roiManager("index") != -1) {
	}
	wait(10);
	
	nROIs = roiManager("count");
	XYT = newArray(3 * nROIs);
	selectWindow_(imageTitle);
	for (cntr = 0; cntr < nROIs; cntr++) {
		selectWindow_(imageTitle);
		roiManager("select", cntr);
		while (roiManager("index") != cntr) {
		}
		wait(10);
		selectWindow_(imageTitle);
		getSelectionBounds(xSel, ySel, widthSel, heightSel);
		XYT[cntr + 0 * nROIs] = xSel + widthSel / 2;
		XYT[cntr + 1 * nROIs] = ySel + heightSel / 2;
		XYT[cntr + 2 * nROIs] = getSliceNumber();
		roiManager("Deselect");
		while (roiManager("index") != -1) {
		}
	}
	roiManager("Deselect");
	roiManager("Delete");
	while (roiManager("count") != 0)  {
	}
	selectWindow_(imageTitle);
	run("Select None");
	//run("Remove Overlay");
	//setTool("rectangle");
	wait(10);
	return XYT;
}

function getTubeCoordinatesOld(currentTitle) {
	N = 12;		//previously N = 9;
	selectWindow_(currentTitle);
	width = getWidth();
	tubeCoordinates = newArray(N);
	for (cntr = 0; cntr < N; cntr++) {
		tubeCoordinates[cntr] = floor(cntr * width / N);
	}
	return tubeCoordinates;
}

function open_(imagePath) {
	nImages_ = nImages;
	open(imagePath);
	while(nImages_ == nImages) {
	}
	return getTitle;
}


function Initialize() {
  	print("\\Clear");
	wait(1);

	run("ROI Manager...");
  	roiManager("reset");
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");
		while (roiManager("count") != 0)  {
		}
		wait(1);
	}
  	wait(1);
  	
  	setBatchMode("exit and display");
	wait(1);
	run("Close All");
	while (nImages > 0) {
	}

	list = getList("window.titles");
	if (list.length > 0) {
		for (i=0; i<list.length; i++) {
			selectWindow(list[i]);
			run("Close");
			while (isOpen(list[i])) {
			}
		}
	}

	run("Clear Results");
	updateResults();
	wait(1);
	run("Set Measurements...", "area integrated redirect=None decimal=2");
	run("Input/Output...", "jpeg=85 gif=-1 file=.txt copy_column save_column");
}

function close_(imageTitle) {
	close(imageTitle);
	while (isOpen(imageTitle)) {
	}
}

function rename_(imageTitle) {
	rename(imageTitle);
	while (getTitle != imageTitle) {
	}
}

function array2String(x) {
	N = lengthOf(x);
	xString = "";
	for (cntr = 0; cntr < N; cntr++) {
		xString += "" + x[cntr];
		if (cntr < (N - 1)) {
			xString += "" + ", ";
		}
	}

	logFlag = false;
	if (logFlag) {
		print("The following " + N + "-element array was converted to a single string:");
		for (cntr = 0; cntr < N; cntr++) {
			print("x[" + cntr + "] = " + x[cntr]);
		}
		print(xString);
	}

	return xString;
}

function string2Array(xString) {
	nString = lengthOf(xString);

	N = 0;
	currentCommaIndex = 0;
	commaIndexArray = newArray(N);
	while (currentCommaIndex >= 0) {
		currentCommaIndex = indexOf(xString, ",", currentCommaIndex + 1);
		if (currentCommaIndex >= 0) {
			N++;
			commaIndexArray = Array.concat(commaIndexArray, currentCommaIndex);
		}
	}

	x = newArray(N + 1);
	if (N > 0) {
		firstIndex = 0;
		lastIndex = commaIndexArray[0] - 1;
		x[0] = "" + substring(xString, firstIndex, lastIndex + 1);
		if (N > 1) {
			for (cntr = 1; cntr < N; cntr++) {
				firstIndex = commaIndexArray[cntr - 1] + 2;
				lastIndex = commaIndexArray[cntr] - 1;
				x[cntr] = "" + substring(xString, firstIndex, lastIndex + 1);  
			}
		}
		firstIndex = commaIndexArray[N - 1] + 2;
		lastIndex = nString - 1;
		x[N] = "" + substring(xString, firstIndex, lastIndex + 1);
	} else {
		x[0] = "" + xString;
	}

	logFlag = false;
	if (logFlag) {
		print("The following string was converted into a " + (N + 1) + "-element array:");
		print(xString);
		for (cntr = 0; cntr <= N; cntr++) {
			print("x[" + cntr + "] = " + x[cntr]);
		}
	}

	return x;
}
