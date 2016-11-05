macro "Main" {
	Initialize();

	groupDir = getDirectory("Please choose the GROUP directory (including L1, L2, ... and B1, B2, ... images)");
	imageFilesList = getFileList(groupDir);
	Array.print(imageFilesList);
	nExperiments = lengthOf(imageFilesList);
	for (cntr = 0; cntr < nExperiments; cntr++) {
		currentFileName = imageFilesList[cntr];
		if (startsWith(currentFileName, "L")) {
			landmarkPath = currentFileName;
			mainPath = "B" + substring(currentFileName, 1, lengthOf(currentFileName));
			stackParams = openStacks(landmarkPath, mainPath);
			landmarkXYReg = getLandmarkXYReg(stackParams);
			mainXYReg = getMainXYReg(stackParams, landmarkXYReg);
			registerLandmark(stackParams, landmarkXYReg);
			registerMain(stackParams, mainXYReg);
		}
	}
}

function getGroupDirectory() {
	verifyGroupFlag = true;
	entitiesList = getFileList(groupDir);
	nEntities = lengthOf(entitiesList);
	nFolders = 0;
	nFiles = 0;
	print("\\Clear");
	for (cntr = 0; cntr < nEntities; cntr++) {
		currentEntitty = entitiesList[cntr];
		if (substring(currentEntitty, lengthOf(currentEntitty) - 1) == "/") {
			print("Subdirectory " + (++nFolders) + ": " + currentEntitty);
		} else {
			print("File " + (++nFiles) + ": " + currentEntitty);
		}
	}
	entitiesList = Array.concat(groupDir, entitiesList);
	if (nFiles > 0) {
		waitForUser("No files are allowed in the GROUP directory (currently " + nFiles + ")");
		wait(1);
		entitiesList = "";
	} else if (nFolders == 0) {
		waitForUser("No subdirectories were found in the GROUP directory");
		wait(1);
		entitiesList = "";
	} else if (verifyGroupFlag) {
		if (!getBoolean("Analyzing the " + nFolders + " subdirectories? (see the Log Window)")) {
			entitiesList = "";
		}
	}
	return entitiesList;
}

function registerMain(stackParams, mainXYReg) {
	mainTitle = stackParams[2];
	nMFrames = parseInt(stackParams[3]);
	nMFrames_1 = nMFrames - 1;
	registeredMainTitle = "Registered_" + mainTitle;
	compositeMainTitle = "Composite_" + mainTitle;

	nImages_ = nImages;
	selectWindow_(mainTitle);
	showStatus("Duplicating the Main stack");
	run("Duplicate...", "title=[" + registeredMainTitle + "] duplicate");
	while (nImages_ == nImages) {
	}

	showStatus("Registering the Main stack");
	for (cntr = 0; cntr < nMFrames_1; cntr++) {
		selectWindow_(registeredMainTitle);
		setSlice(cntr + 2);
		x = mainXYReg[2 * cntr + 0];
		y = mainXYReg[2 * cntr + 1];
		run("Translate...", "x=" + x + " y=" + y + " interpolation=Bilinear slice");
	}
	showStatus("Merging the original/registered Main stacks");
	run("Merge Channels...", "c1=[" + mainTitle + "] c2=[" + registeredMainTitle + "] create keep");	
	while (!isOpen("Composite")) {
	}
	renameImage("Composite", compositeMainTitle);
}

function getMainXYReg(stackParams, landmarkXYReg) {
	mainXYReg = 0;

	nLFrames = parseInt(stackParams[1]);
	nMFrames = parseInt(stackParams[3]);
	firstLFrame = parseInt(stackParams[4]);
	stepLFrame = parseInt(stackParams[5]);
	nLFrames_1 = nLFrames - 1;
	nMFrames_1 = nMFrames - 1;

	mFrame_1 = newArray(nMFrames_1);
	for (cntr = 0; cntr < nMFrames_1; cntr++) {
		mFrame_1[cntr] = cntr + 1;
	}
	
	lFrame_1 = newArray(nLFrames_1);
	for (cntr = 0; cntr < nLFrames_1; cntr++) {
		lFrame_1[cntr] = firstLFrame + cntr * stepLFrame;
	}

	mainXYReg = newArray(2 * nMFrames_1);
	for (cntr = 0; cntr < nMFrames_1; cntr++) {
		mainFrame_1 = mFrame_1[cntr];
		mainFrame_2 = mFrame_1[cntr] + 1;
		landmarkOwnFrame_1 = 1 + floor((mainFrame_1 - lFrame_1[0]) / stepLFrame);
		
		if (landmarkOwnFrame_1 < 1) {
			landmarkOwnFrame_1 = 1;
			print("Registration of frame " + mainFrame_1 + " is with EXTRApolation (of landmark registrations).");
		} else if (landmarkOwnFrame_1 >= nLFrames_1) {
			landmarkOwnFrame_1 = nLFrames_1 - 1;
			print("Registration of frame " + mainFrame_2 + " is with EXTRApolation (of landmark registrations).");
		}
		landmarkFrame_1 = lFrame_1[landmarkOwnFrame_1 - 1];

		xL = landmarkXYReg[2 * (landmarkOwnFrame_1 - 1) + 0];
		xLP1 = landmarkXYReg[2 * (landmarkOwnFrame_1 - 0) + 0];
		x = xL + (xLP1 - xL) * (mainFrame_1 - landmarkFrame_1) / (stepLFrame);

		yL = landmarkXYReg[2 * (landmarkOwnFrame_1 - 1) + 1];
		yLP1 = landmarkXYReg[2 * (landmarkOwnFrame_1 - 0) + 1];
		y = yL + (yLP1 - yL) * (mainFrame_1 - landmarkFrame_1) / (stepLFrame);

		mainXYReg[2 * cntr + 0] = x;
		mainXYReg[2 * cntr + 1] = y;
	}
	return mainXYReg;
}

function registerLandmark(stackParams, landmarkXYReg) {
	landmarkTitle = stackParams[0];
	nLFrames = parseInt(stackParams[1]);
	nLFrames_1 = nLFrames - 1;
	registeredLandmarkTitle = "Registered_" + landmarkTitle;
	compositeLandmarkTitle = "Composite_" + landmarkTitle;

	nImages_ = nImages;
	selectWindow_(landmarkTitle);
	showStatus("Duplicating the Landmark stack");
	run("Duplicate...", "title=[" + registeredLandmarkTitle + "] duplicate");
	while (nImages_ == nImages) {
	}
	
	showStatus("Registering the Landmark stack");
	for (cntr = 0; cntr < nLFrames_1; cntr++) {
		selectWindow_(registeredLandmarkTitle);
		setSlice(cntr + 2);
		x = landmarkXYReg[2 * cntr + 0];
		y = landmarkXYReg[2 * cntr + 1];
		run("Translate...", "x=" + x + " y=" + y + " interpolation=Bilinear slice");
	}
	showStatus("Merging the original/registered Landmark stacks");
	run("Merge Channels...", "c1=[" + landmarkTitle + "] c2=[" + registeredLandmarkTitle + "] create keep");	
	while (!isOpen("Composite")) {
	}
	renameImage("Composite", compositeLandmarkTitle);
}

function getLandmarkXYReg(stackParams) {
	setBatchMode(true);
	landmarkTitle = stackParams[0];
	nLSlices = parseInt(stackParams[1]);

	nLSlices_1 = nLSlices - 1;
	landmarkXYReg = newArray(nLSlices_1 * 2);

	testFlag = false;
	if (testFlag) {
		showStatus("Thresholding landmark slices");
		for (pairCntr = 0; pairCntr < nLSlices; pairCntr++) {
			showProgress(pairCntr, nLSlices_1);
			selectWindow_(landmarkTitle);
			setSlice_(pairCntr + 1);

			tempTitle = landmarkTitle + "_Slice_" + (pairCntr + 1);
			run("Duplicate...", "title=[" + tempTitle + "]");
			getStatistics(area, mean, min, max, std, histogram);
			close_(tempTitle);

			selectWindow_(landmarkTitle);
			setAutoThreshold("Default dark");
			getThreshold(lower, upper);
			resetThreshold();
			run("Macro...", "code=[v = " + min + " + (v - " + min + ") * (v >= " + lower + ") * (v <= " + upper + ")]");		
		}
	}

	showStatus("Finding landmark shifts");
	sumX = 0;
	sumY = 0;
	for (pairCntr = 0; pairCntr < nLSlices_1; pairCntr++) {
		showProgress(pairCntr, nLSlices_1);
		optimalXYShift = getOptimalXYShift(stackParams, pairCntr);
		sumX += optimalXYShift[0];
		sumY += optimalXYShift[1];
		//landmarkXYReg[2 * pairCntr + 0] = sumX;
		//landmarkXYReg[2 * pairCntr + 1] = sumY;
		landmarkXYReg[2 * pairCntr + 0] = optimalXYShift[0];
		landmarkXYReg[2 * pairCntr + 1] = optimalXYShift[1];
	}
	setBatchMode("exit and display");

	debugFlag = true;
	if (debugFlag) {
		print("\nlandmarkXYReg:");
		Array.print(landmarkXYReg);
	}
	
	return landmarkXYReg;
}

function getOptimalXYShift(stackParams, pairCntr) {
	landmarkTitle = stackParams[0];
	maxShiftPixels = parseInt(stackParams[6]);
	subPixelPoints = parseInt(stackParams[7]);

	//image1Title = landmarkTitle + "_Slice_" + (pairCntr + 1);
	image1Title = landmarkTitle + "_Slice_" + (0 + 1);
	image2Title = landmarkTitle + "_Slice_" + (pairCntr + 2);
	selectWindow_(landmarkTitle);
	//setSlice_(pairCntr + 1);
	setSlice_(0 + 1);
	run("Duplicate...", "title=[" + image1Title + "]");
	removeMean(image1Title);
	applyEdgeMask(image1Title, maxShiftPixels);
	
	
	selectWindow_(landmarkTitle);
	setSlice_(pairCntr + 2);
	run("Duplicate...", "title=[" + image2Title + "]");
	removeMean(image2Title);

	//setBatchMode("exit and display");waitForUser;setBatchMode(true);

	gridStep = 1 / (subPixelPoints + 1);
	Cntr = 0;
	for (x = - maxShiftPixels; x <= maxShiftPixels; x += gridStep) {
		for (y = - maxShiftPixels; y <= maxShiftPixels; y += gridStep) {
			currentCorr = getImageCorr(image1Title, image2Title, x, y);
			if (Cntr == 0) {
				optimalXYShift = newArray(x, y);
				optimalCorr = currentCorr;
				Cntr++;
			} else {
				if (currentCorr > optimalCorr) {
					optimalXYShift = newArray(x, y);
					optimalCorr = currentCorr;
				}
			}
		}
	}
	close_(image1Title);
	close_(image2Title);

	debugFlag = false;
	if (debugFlag) {
		print("Landmark transition (" + (pairCntr + 1) + " to " + (pairCntr + 2) + "): optimalCorr = " + optimalCorr + ", optimal Dx = " + optimalXYShift[0] + ", optimal Dy = " + optimalXYShift[1]);
	}
	return optimalXYShift;
}

function removeMean(imageTitle) {
	selectWindow_(imageTitle);
	run("32-bit");
	getStatistics(area, mean, min, max, std, histogram);
	run("Subtract...", "value=" + mean);	
}

function applyEdgeMask(imageTitle, maxShiftPixels) {
	while (!isOpen(imageTitle)) {
	}
	selectWindow_(imageTitle);
	run("Macro...", "code=[v = v * (((x >= " + maxShiftPixels + ") & (w-1-x>=" + maxShiftPixels + ")) * ((y >= " + maxShiftPixels + ") & (h-1-y>=" + maxShiftPixels + ")))]");
}

function getImageCorr(image1Title, image2Title, x, y) {
	copyTitle = image2Title + "_Copy";
	selectWindow_(image2Title);
	run("Duplicate...", "title=[" + copyTitle + "]");
	run("Translate...", "x=" + x + " y=" + y + " interpolation=Bilinear");

	nImages_ = nImages;
	imageCalculator("Multiply create 32-bit", image1Title, copyTitle);
	while (nImages_ == nImages) {
	}
	getStatistics(area, meanProduct, min, max, std, histogram);
	close_(getTitle());

	nImages_ = nImages;
	imageCalculator("Multiply create 32-bit", image1Title, image1Title);
	while (nImages_ == nImages) {
	}
	getStatistics(area, meanImage1, min, max, std, histogram);
	close_(getTitle());

	nImages_ = nImages;
	imageCalculator("Multiply create 32-bit", copyTitle, copyTitle);
	while (nImages_ == nImages) {
	}
	getStatistics(area, meanImage2, min, max, std, histogram);
	close_(getTitle());

	currentCorr = meanProduct / sqrt(meanImage1 * meanImage2);
	currentCorr = (2 / PI) * asin(currentCorr);
	close_(copyTitle);
	return currentCorr;
}

function openStacks(landmarkPath, mainPath) {
	nStackParams = 8;
	stackParams = newArray(nStackParams);
	Cntr = 0;

	nImages_ = nImages;
	open(landmarkPath);
	while (nImages == nImages_) {
	}
	currentTitle = getTitle();
	renameImage(currentTitle, "Landmark_" + currentTitle);
	stackParams[Cntr++] = getTitle();
	stackParams[Cntr++] = "" + nSlices;
	
	nImages_ = nImages;
	open(mainPath);
	while (nImages == nImages_) {
	}
	currentTitle = getTitle();
	renameImage(currentTitle, "Main_" + currentTitle);
	stackParams[Cntr++] = getTitle();
	stackParams[Cntr++] = "" + nSlices;

	estimatedFrameStep = - floor(- parseInt(stackParams[3]) / parseInt(stackParams[1]) );
	maxShiftPixels = 8;
	subPixelPoints = 0;

	manualModeFlag = false;
	if (manualModeFlag) {
		Dialog.create("Matching stacks indices");
		Dialog.addNumber("First Landmark frame (in Main stack):", 1);
		Dialog.addNumber("Step of Landmark frames (in Main stack):", estimatedFrameStep);
		Dialog.addNumber("Maximum shift in pixels:", maxShiftPixels);
		Dialog.addNumber("Number of sub-pixel grid points:", subPixelPoints);
		Dialog.show;
		stackParams[Cntr++] = "" + Dialog.getNumber;
		stackParams[Cntr++] = "" + Dialog.getNumber;
		stackParams[Cntr++] = "" + Dialog.getNumber;
		stackParams[Cntr++] = "" + Dialog.getNumber;
	} else {
		stackParams[Cntr++] = "" + 1;
		stackParams[Cntr++] = "" + estimatedFrameStep;
		stackParams[Cntr++] = "" + maxShiftPixels;
		stackParams[Cntr++] = "" + subPixelPoints;
	}
	
	debugFlag = true;
	if (debugFlag) {
		print("stackParams:");
		Array.print(stackParams);
		print("\n");
	}

	return stackParams;
}

function renameImage(imageTitleOld, imageTitleNew) {
	selectWindow_(imageTitleOld);
	rename(imageTitleNew);
	while (getTitle != imageTitleNew) {
	}
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle() != imageTitle) {
	}
}

function setSlice_(n){
	setSlice(n);
	while (getSliceNumber != n) {
	}
}

function close_(imageTitle) {
	close(imageTitle);
	while(isOpen(imageTitle)) {
	}
}

function openImage(imagePath) {
	nImages_ = nImages;
	open (imagePath);
	while (nImages == nImages_) {
	}
	return getTitle();
}

function Initialize() {
	setBatchMode("exit and display");
	wait(1);
	run("Close All");
	print("\\Clear");
	while (nImages > 0) {
	}
	setBatchMode(true);
}

