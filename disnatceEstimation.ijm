macro "Main" {
	closeFlag = true;
	Initialize(closeFlag);
	setBatchMode(false);

	//rasterFlag = false; nX = 20; nXH = floor(nX / 2);a = newArray(nX, nX, rasterFlag, false, true); XY = rasterScan(a);selectWindow("X");run("Set... ", "zoom=800 x="+nXH+" y="+nXH);getLocationAndSize(x, y, width, height);setLocation(0, 0);selectWindow("Y");run("Set... ", "zoom=800 x="+nXH+" y="+nXH);setLocation(width, 0);return;
	
	//imgSourceOptions = newArray("Analyze all cells", "Review the results", "Verify the program", "Analyze selected cells");
	imgSourceOptions = newArray("Analyze all cells", "Review the results", "Verify the program");
	Dialog.create("Radio Button");
	Dialog.addRadioButtonGroup("Please choose: ", imgSourceOptions, 
								lengthOf(imgSourceOptions), 1, imgSourceOptions[0]);
	Dialog.show;
	selectedAction = Dialog.getRadioButton;
	if (selectedAction == imgSourceOptions[2]) {
		dialogFlag = true;
		hotSpotsImageID = simulateHotSpots(dialogFlag);
		width = getWidth;
		height = getHeight;
		nDGX = width;
		nDGY = height;
		Amp1 = 1;
		SigmaTwo1 = 3;
		Amp2 = 1;
		SigmaTwo2 = 3;
		fdgParam_in = newArray(Amp1, NaN, NaN, SigmaTwo1, Amp2, NaN, NaN, SigmaTwo2, nDGX, nDGY);
		print("Input parameters of the fit program:");
		Array.print(fdgParam_in);
		fdgParam = fitDoubleGaussian(hotSpotsImageID, fdgParam_in);
		print("");
	} else {

		//Please edit here!
		filePath = ...;
		fileROIResults = ...;
		roiTableFile = ...;
		fileStackPath = ...;
		//
		
		fileStackID = NaN;
		compositeFlag = true;
		if (selectedAction == imgSourceOptions[0]) {
			browseFlag = false;
			fcdParam = newArray(filePath, fileStackID, fileROIResults, roiTableFile, compositeFlag, browseFlag);
			fcdOutput = findCentrosomeDistances(fcdParam);
		} else if (selectedAction == imgSourceOptions[1]) {
			show3DFlag = false;
			if (show3DFlag) {
				run("3D Viewer");
				call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
				open(fileStackPath);
				run("Split Channels");
				wait(1);
				close("C1-" + File.name);
				wait(1);
				close("C3-" + File.name);
				wait(1);
				selectWindow("C2-" + File.name);
				rename("Hyperstack.tif");
				run("Enhance Contrast", "saturated=0");
				fileStackID = getImageID();
			} else {
				fileStackID = NaN;
			}
			dcdParam = newArray(filePath, fileStackID, fileROIResults, roiTableFile);
			dcdOutput = displayCentrosomeDistances(dcdParam);
		} else if (selectedAction == imgSourceOptions[3]) {
			browseFlag = true;
			fcdParam = newArray(filePath, fileStackID, fileROIResults, roiTableFile, compositeFlag, browseFlag);
			fcdOutput = findCentrosomeDistances(fcdParam);
		}
	}
}

function displayCentrosomeDistances(dcdParam) {
	filePath = dcdParam[0];
	fileStackID = dcdParam[1];
	fileROIResults = dcdParam[2];
	roiTableFile = dcdParam[3];

	displayFlag = true;
	imageTitle = "Stack.tif";
	
	
	
	wait(1);
	wait(1);
	open(filePath);
	wait(1);
	Stack.setDisplayMode("composite");
	wait(1);
	stackID = getImageID();
	wait(1);
	stackID = preProcessCurrentStack(stackID, compositeFlag);
	waitForUser;
	wait(1);
	selectImage(stackID);
	wait(20);
	rename(imageTitle);
	wait(1);
	Stack.getDimensions(width, height, nChannels_, nSlices_, nFrames_);
	wait(1);
	//roiManager("Open", roiTableFile);
	wait(1);
	run("From ROI Manager");
	wait(1);
	run("Hide Overlay");
	wait(1);
	


	wait(1);
	roiManager("Deselect");
	wait(20);
	nCells1 = roiManager("count");
	wait(20);
	channel = 2;
	slice = 1;
	frame = 1;
	Stack.setPosition(channel, slice, frame);
	wait(20);

	loadTable();
	
	// Load the ROI Results Table
	// Upon choice of an ROI entry
		// Show the Stack, green channel cell, ROI + Fit, 3D
		// Highlight the associated row in the table

	newResultsTable = "ROI Results";
	//initializeROIResultsTable(newResultsTable);
	roiImageTitle = "Selected Cell";
	debounceDelay = 20;
	wait(1);
	waitForUser("Select an ROI or {Deselect + Delete} to end");
	wait(1);
	oldCntr = -1;
	wait(1);
	roiManager("Select",0);
	wait(20);
	roiManager("Deselect");
	wait(20);

	

	continueFlag = true;
	while (continueFlag) {
		wait(1);
		selectWindow("ROI Manager");
		wait(20);
		cntr = roiManager("index");
		wait(20);
		if ( (cntr > -1) & (cntr != oldCntr) ){
			wait(debounceDelay);
			wait(1);
			cntr__ = roiManager("index");
			wait(20);
			if (cntr == cntr__) {
				if (isOpen(roiImageTitle)) {
					//print("Position 1");
					selectWindow(roiImageTitle);
					wait(10);
					run("Close");
					wait(10);
					//print("Position 1_");
				}
				tableIndex = cell2TableIndex(cntr);
				roiParamProcess = newArray(stackID, roiImageTitle, cntr, newResultsTable, tableIndex, displayFlag, fileStackID);
				processOutput = processROI(roiParamProcess);
				wait(1);
				selectWindow("Results");
				wait(20);
				//showStatus("Cell "+cntr+" (out of "+nCells1+"), Frame "+frame+" (out of "+nFrames_+")");
				showStatus("Cell "+cntr+" (out of "+nCells1+")");
				//showProgress(cntr, nCells1);
				selectWindow("ROI Manager");
				wait(20);
				oldCntr = cntr;
				wait(debounceDelay);
			}
		}
		wait(1);
		cntr__ = roiManager("count");
		wait(20);
		if (cntr__ == 0) {
			continueFlag = false;
		}
	}
	dcdOutput = true;
	return dcdOutput;
}

function findCentrosomeDistances(fcdParam) {
	filePath = fcdParam[0];
	fileStackID = fcdParam[1];
	fileROIResults = fcdParam[2];
	roiTableFile = fcdParam[3];
	compositeFlag = fcdParam[4];
	browseFlag = fcdParam[5];

	open(filePath);
	wait(1);
	Stack.setDisplayMode("composite");
	wait(1);
	stackID = getImageID();
	stackID = preProcessCurrentStack(stackID, compositeFlag);
	showStatus("Saving ROIs ...");
	wait(1);
	roiManager("Save", roiTableFile);
	wait(1);
	showStatus("");
	selectImage(stackID);
	wait(20);
	rename("Stack.tif");
	wait(1);
	Stack.getDimensions(width, height, nChannels_, nSlices_, nFrames_);
	wait(1);
	run("From ROI Manager");
	run("Hide Overlay");
	
	wait(1);
	roiManager("Deselect");
	wait(20);
	nCells1 = roiManager("count");
	wait(20);
	channel = 2;
	slice = 1;
	frame = 1;
	wait(1);
	Stack.setPosition(channel, slice, frame);
	wait(1);
	newResultsTable = "ROI Results";
	initializeROIResultsTable(newResultsTable);
	roiImageTitle = "Selected Cell";
	debounceDelay = 20;
	wait(1);
	if (browseFlag) {
		wait(1);
		waitForUser("Select an ROI or {Deselect + Delete} to end");
		wait(1);
		roiManager("Select",0);
		wait(20);
		roiManager("Deselect");
		wait(20);
		oldCntr = -1;
		cntr = -1;
		tableIndex = 0;
		continueFlag = true;
		displayFlag = true;
		while (continueFlag) {
			selectWindow("ROI Manager");
			wait(20);
			cntr = roiManager("index");
			wait(20);
			if ( (cntr > -1) & (cntr != oldCntr) ){
				wait(debounceDelay);
				wait(1);
				cntr__ = roiManager("index");
				wait(20);
				if (cntr == cntr__) {
					//tableIndex = cell2TableIndex(cntr);
					roiParamProcess = newArray(stackID, roiImageTitle, cntr, newResultsTable, tableIndex++, displayFlag, fileStackID);
					processOutput = processROI(roiParamProcess);
					wait(1);
					selectWindow(newResultsTable);
					wait(20);
					//showStatus("Cell "+cntr+" (out of "+nCells1+"), Frame "+frame+" (out of "+nFrames_+")");
					showStatus("Cell "+cntr+" (out of "+nCells1+")");
					//showProgress(cntr, nCells1);
					selectWindow("ROI Manager");
					wait(20);
					oldCntr = cntr;
					wait(debounceDelay);
				}
			}
			wait(1);
			cntr__ = roiManager("count");
			wait(20);
			if (cntr__ == 0) {
				continueFlag = false;
			}
		}
	} else {
		displayFlag = false;
		for (cntr = 0; cntr < nCells1; cntr++) {
			roiParamProcess = newArray(stackID, roiImageTitle, cntr, newResultsTable, cntr, displayFlag, fileStackID);
			processOutput = processROI(roiParamProcess);
			//showStatus("Cell "+cntr+" (out of "+nCells1+"), Frame "+frame+" (out of "+nFrames_+")");
			showStatus("Cell "+cntr+" (out of "+nCells1+")");
			showProgress(cntr, nCells1);
			wait(1);
			saveAs("results", fileROIResults);
			wait(1);
			IJ.renameResults("ROI_Results.csv", newResultsTable);
			wait(1);
		}
	}
	wait(1);
	roiManager("Deselect");
	wait(20);
	fcdOutput = true;
	return fcdOutput;
}

function processROI(roiParamProcess) {
	stackID = roiParamProcess[0];
	roiImageTitle = roiParamProcess[1];
	roiIndex = roiParamProcess[2];
	newResultsTable = roiParamProcess[3];
	tableIndex = parseFloat(roiParamProcess[4]);
	displayFlag = roiParamProcess[5];
	fileStackID = roiParamProcess[6];

	print("");
	print("Processing ROI #" + roiIndex + " / Table Index #" + tableIndex + " by processROI(roiParamProcess)");

	wait(1);
	selectImage(stackID);
	wait(10);
	roiManager("select", roiIndex);
	wait(20);
	selectImage(stackID);
	wait(10);
	Stack.getPosition(channel, slice, frame);
	wait(1);
	Roi.getBounds(xulROI, yulROI, widthROI, heightROI);

	xMin = xulROI;
	yMin = yulROI;
	xMax = xMin + widthROI;
	yMax = yMin + heightROI;
	nX = 1 + widthROI;
	nY = 1 + heightROI;
	nBoundRectData =  nX * nY;

	boundRectData = newArray(nBoundRectData);
	Cntr = 0;
	for (y = yMin; y <= yMax; y++) {
		for (x = xMin; x <= xMax; x++) {
			if (Roi.contains(x, y) == true) {
				boundRectData[Cntr++] = getPixel(x, y);
			} else {
				boundRectData[Cntr++] = 0;
			}
		}
	}
	Array.getStatistics(boundRectData, minData, maxData, meanData, stdDevData);
	//Array.print(boundRectData); return;

	imageType = "32-bit";
	imageWidth = nX;
	imageHeight = nY;
	imageDepth = 1;
	xOffset = maxOf(10, round(0.1 * nX));
	//imageWidth__ = 2 * imageWidth + xOffset;
	imageWidth__ = imageWidth;
	if (isOpen(roiImageTitle)) {
		//print("Position 5");
		selectWindow(roiImageTitle);
		wait(10);
		run("Close");
		//print("Position 5_");
		wait(10);
	}
	wait(20);
	newImage(roiImageTitle, imageType, imageWidth__, imageHeight, imageDepth);
	wait(20);
	roiID = getImageID();

	//imageWidth__ = imageWidth + 2 * xOffset;
	
	greenThresholdHigh = 260;
	//Thresholded ROI image
	Cntr = 0;
	for (y = 0; y < nY; y++) {
		for (x = 0; x < nX; x++) {
			setPixel(x, y, boundRectData[Cntr++]);
		}
		//for (x = nX; x < imageWidth__; x++) {
		//	setPixel(x, y, 0);
		//}
	}
	//wait(1);
	if (!displayFlag) {
		run("Clear Results");
		run("Find Maxima...", "noise="+ greenThresholdHigh +" output=[List]");
		updateResults();
		nMaxima = nResults;
	} else {
		nMaxima = getResult("n(Max)", tableIndex);
	}
	run("Enhance Contrast", "saturated=0");
	run("Select None");
	wait(10);
	
	if (!displayFlag) {
		dgsParam = updateROIResults(nMaxima, newResultsTable, roiIndex, frame, tableIndex, roiID);
	} else {
		print("nMaxima = 1 detected");
		if (nMaxima == 1) {
			displayOriginalandFit(roiID, tableIndex);
		}
		if (!isNaN(fileStackID)) {
			selectImage(fileStackID);
			roiManager("select", roiIndex);
			wait(20);
			run("Duplicate...", "title=hyperSelection duplicate frames=" + (roiID + 1));
			while(!isOpen("hyperSelection")) {
			}
			wait(1);
			selectWindow("hyperSelection");
			wait(1);
			run("Select None");
			wait(1);
			call("ij3d.ImageJ3DViewer.add", "hyperSelection", "White", "hyperSelection", "0", "true", "true", "true", "1", "0");
			call("ij3d.ImageJ3DViewer.startAnimate");
			wait(10);
		}
	}
	processOutput = true;
	return processOutput;
}

function updateROIResults(nMaxima, roiResultsTable, cellIndex, frameIndex, tableIndex, roiID) {
	if (nMaxima > 0) {
		X = newArray(nMaxima);
		Y = newArray(nMaxima);
		for (cntr = 0; cntr < nMaxima; cntr++) {
			X[cntr] = getResult("X", cntr);
			Y[cntr] = getResult("Y", cntr);
		}
	}
	tempResults = "Temporary_Results";
	IJ.renameResults("Results", tempResults);
	wait(1);
	IJ.renameResults(roiResultsTable, "Results");
	wait(1);
	setResult("Cell", tableIndex, cellIndex + 1);
	setResult("n(Max)", tableIndex, nMaxima);
	setResult("Frame", tableIndex, frameIndex);
	updateResults();
	if (nMaxima > 0) {
		for (cntr = 0; cntr < nMaxima; cntr++) {
			setResult("X"+(cntr + 1), tableIndex, X[cntr]);
			setResult("Y"+(cntr + 1), tableIndex, Y[cntr]);
		}
		if (nMaxima == 1) {
			clearROIFlag = false;
			if (clearROIFlag) {
				wait(1);
				selectImage(stackID);
				wait(1);
				roiManager("Deselect");
				wait(20);
				roiManager("Delete");
				wait(20);
			}
			setResult("Distance", tableIndex, "Plz wait!");
			wait(1);
			updateResults();
			wait(20);
			xMax = X[0];
			yMax = Y[0];
			nMaxima_ = 3;
			nDGX = 21;
			nDGY = 21;
			Amp1 = 1;
			Amp2 = 1;
			SigmaTwo1 = 1;
			SigmaTwo2 = 1;
			dgsParam = newArray(Amp1, NaN, NaN, SigmaTwo1, Amp2, NaN, NaN, SigmaTwo2, nDGX, nDGY);
			dgsParam = fitDoubleGaussian(roiID, dgsParam);
			Amp1 = dgsParam[0];
			cDGX1 = dgsParam[1];
			cDGY1 = dgsParam[2];
			SigmaTwo1 = dgsParam[3];
			Amp2 = dgsParam[4];
			cDGX2 = dgsParam[5];
			cDGY2 = dgsParam[6];
			SigmaTwo2 = dgsParam[7];
			nDGX = dgsParam[8];
			nDGY = dgsParam[9];

			setResult("Amp1", tableIndex, dgsParam[0]);
			setResult("cDGX1", tableIndex, dgsParam[1]);
			setResult("cDGY1", tableIndex, dgsParam[2]);
			setResult("SigmaTwo1", tableIndex, dgsParam[3]);
			setResult("Amp2", tableIndex, dgsParam[4]);
			setResult("cDGX2", tableIndex, dgsParam[5]);
			setResult("cDGY2", tableIndex, dgsParam[6]);
			setResult("SigmaTwo2", tableIndex, dgsParam[7]);
			setResult("nDGX", tableIndex, dgsParam[8]);
			setResult("nDGY", tableIndex, dgsParam[9]);

			//print("The best two-point fit occurs (in DG coordinates) for (" + dgsParam[1] + ", " + dgsParam[2] + ") and (" + dgsParam[5] + ", " + dgsParam[6] + ")");

			cntrsmDistance = sqrt( pow(cDGX2 - cDGX1, 2) + pow(cDGY2 - cDGY1, 2) );
			setResult("Distance", tableIndex, cntrsmDistance);
			if (clearROIFlag) {
				selectImage(stackID);
				run("To ROI Manager");					
				wait(1);
				roiManager("select", cntr);
				wait(20);
				roiManager("Deselect");
				wait(20);
			}
		} else if (nMaxima == 2) {
			cntrsmDistance = sqrt( pow(X[1] - X[0], 2) + pow(Y[1] - Y[0], 2) );
			setResult("Distance", tableIndex, parseFloat(toString(cntrsmDistance, 1)));
			dgsParam = cntrsmDistance;
		} else {
			nMaxima_ = 3;
		}
	}
	IJ.renameResults("Results", roiResultsTable);
	wait(1);
	IJ.renameResults(tempResults, "Results");
	wait(1);
	selectWindow(roiResultsTable);
	wait(1);
			
	return dgsParam;
}

function fitDoubleGaussian(roiID, dgsParam) {
	Amp1 = dgsParam[0];
	SigmaTwo1 = dgsParam[3];
	Amp2 = dgsParam[4];
	SigmaTwo2 = dgsParam[7];
	nX_ = dgsParam[8];
	nY_ = dgsParam[9];

	n2D = nX_ * nY_;
	xMean = floor( (nX_ - 1) / 2 );
	yMean = floor( (nY_ - 1) / 2 );

	selectImage(roiID);
	wait(2);
	dummy_1 = brightestSpot(roiID);
	selectImage(roiID);
	wait(2);
	xMax = dummy_1[0];
	yMax = dummy_1[1];
	iMax = dummy_1[2];
	//iMax = getPixel(xMax, yMax);

	roiImageData = newArray(n2D);
	Cntr = 0;
	for (y = 0; y < nY_; y++) {
		for (x = 0; x < nX_; x++) {
			roiImageData[Cntr++] = getPixel(xMax - xMean + x, yMax - yMean +y);
		}
	}
	meanA = 0;
	for (cntr = 0; cntr < n2D; cntr++) {
		meanA += roiImageData[cntr];
	}
	meanA /= n2D;
	for (cntr = 0; cntr < n2D; cntr++) {
		roiImageData[cntr] -= meanA;
	}
	VarA_ = 0;
	for (cntr = 0; cntr < n2D; cntr++) {
		dummy_1 = roiImageData[cntr];
		VarA_ += dummy_1 * dummy_1;
	}


	debugFlag = false;
	if (debugFlag) {
		title_ = getTitle();

		//Please edit here!
		currentROIImageFile = ...;
		//
		
		saveAs("Tiff", currentROIImageFile);
		wait(10);
		rename(title_);
		wait(10);
		
		Array.show(roiImageData);
		waitForUser("Please check the ROI Image and the acquired array.");
		wait(1);
		selectWindow("roiImageData");
		wait(1);
		run("Close");
		wait(20);
		print("Reading the ROI Image: nX_ = " + nX_ + ", nY_ = " + nY_ + ", n2D = " + n2D);
	}

	
	// imageP1Amp, imageP1x, imageP1y, imageP1Sigma2, imageP2Amp, imageP2x, imageP2y, imageP2Sigma2, nX, nY
	// dgsParam[0], dgsParam[1], dgsParam[2], dgsParam[3], dgsParam[4], dgsParam[5], dgsParam[6], dgsParam[7], dgsParam[8], dgsParam[9] 
	sigmaMin = sqrt(2);
	sigmaMax = maxOf(2, floor(sqrt(minOf(nX_,nY_) / 2)));
	sigma0 = 3;
	nXH = floor(nX_ / 2);
	nYH = floor(nY_ / 2);

	showStatus("Correlations ...");

	dgsScanFlag = newArray(false, true, true, false, false, true, true, false, false, false);
	dgsMin = newArray(Amp1, 0, 0, sigmaMin, 0.1, 0, 0, sqrt(2), nX_, nY_);
	dgsMax = newArray(Amp1, nX_ - 1, nY_ - 1 , sigmaMax, 0.9, nX_ - 1, nY_ - 1, sigmaMax, nX_, nY_);
	dgsN = newArray(1, nX_, nY_, 3, 3, nX_, nY_, 3, 1, 1);
	dgsDefault = newArray(Amp1, nXH, nYH, sigma0, Amp2, nXH, nYH, sigma0, nX_, nY_);

	ndgsParam = lengthOf(dgsDefault);
	nParamSet = 1;
	dgsStep = newArray(ndgsParam);
	for (cntr = 0; cntr < ndgsParam; cntr++) {
		if (dgsScanFlag[cntr]) {
			dgsStep[cntr] = (dgsMax[cntr] - dgsMin[cntr]) / (dgsN[cntr] - 1);
			nParamSet *= dgsN[cntr];
		} else {
			dgsMin[cntr] = dgsDefault[cntr];
			dgsMax[cntr] = dgsMin[cntr];
			dgsStep[cntr] = 1;
		}
	}

	nParamSet_ = nParamSet / 4;
	Counter = 0;
	bestParam = dgsDefault;
	bestCorrelation = 0;
	AllCov = newArray(nParamSet);

    for (c8 = dgsMin[8]; c8 <= dgsMax[8]; c8 += dgsStep[8]) {
     for (c9 = dgsMin[9]; c9 <= dgsMax[9]; c9 += dgsStep[9]) {

	  for (c3 = dgsMin[3]; c3 <= dgsMax[3]; c3 += dgsStep[3]) {
	   for (c0 = dgsMin[0]; c0 <= dgsMax[0]; c0 += dgsStep[0]) {

	    //for (c1 = dgsMin[1]; c1 <= dgsMax[1]; c1 += dgsStep[1]) {
	    dgsMin1_ = maxOf(c3, dgsMin[1]);
	    dgsMax1_ = minOf(c8 - c3, dgsMax[1]);
	    for (c1 = dgsMin1_; c1 <= dgsMax1_; c1 += dgsStep[1]) {
	     //for (c2 = dgsMin[2]; c2 <= dgsMax[2]; c2 += dgsStep[2]) {
	     dgsMin2_ = maxOf(c3, dgsMin[2]);
	     dgsMax2_ = minOf(c9 - c3, dgsMax[2]);;
	     for (c2 = dgsMin2_; c2 <= dgsMax2_; c2 += dgsStep[2]) {

          for (c7 = dgsMin[7]; c7 <= dgsMax[7]; c7 += dgsStep[7]) {
	       for (c4 = dgsMin[4]; c4 <= dgsMax[4]; c4 += dgsStep[4]) {

	        //for (c5 = dgsMin[5]; c5 <= dgsMax[5]; c5 += dgsStep[5]) {
	        dgsMin5_ = maxOf(c1 + 1, maxOf(c7, dgsMin[5]));
	        dgsMax5_ = minOf(c8 - c7, dgsMax[5]);
	        for (c5 = dgsMin5_; c5 <= dgsMax5_; c5 += dgsStep[5]) {
	         //for (c6 = dgsMin[6]; c6 <= dgsMax[6]; c6 += dgsStep[6]) {
	         dgsMin6_ = maxOf(c7, dgsMin[6]);
	         dgsMax6_ = minOf(c9 - c7, dgsMax[6]);
	         for (c6 = dgsMin6_; c6 <= dgsMax6_; c6 += dgsStep[6]) {

			  //if ( ( (c5 < c1) & (c6 < c2) ) | true) {

				dgsParam = newArray(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9);

				// One-time-only correlation-related calculations for roiImageData;
				// Deleting the division by Std of roiImageData
				// Direct implementation and no use of functions

				synthImageData = synthesizeDoubleGaussian(dgsParam);

				meanB = 0;
				for (cntr = 0; cntr < n2D; cntr++) {
					meanB += synthImageData[cntr];
				}
				meanB /= n2D;
				VarB_ = 0;
				VarAB_ = 0;
				for (cntr = 0; cntr < n2D; cntr++) {
					dummy_1 = roiImageData[cntr];
					dummy_2 = synthImageData[cntr] - meanB;
					VarB_ += dummy_2 * dummy_2;
					VarAB_ += dummy_1 * dummy_2;
				}
				covCff = VarAB_ / sqrt(VarA_ * VarB_);
				if (bestCorrelation < covCff) {
				//if (abs(bestCorrelation) < abs(covCff)) {
				 	bestCorrelation = covCff;
				 	bestParam = dgsParam;
				}
				AllCov[Counter] = covCff;
				showProgress(Counter++, nParamSet_);


			  //}	

				
	         }
	        }
	       }
	      }
	     }
	    }
	   }
	  }
	 }
	}
  showProgress(0.99);

	// If iMax is located oustide of the bounding rectangel of estimated C1-C2, then no conclusion.
	
	//dgParam = newArray(bestParam[1], bestParam[2], bestParam[5], bestParam[6]);
	print("Best Double-Gaussian Centers: (" + 
		(xMax - xMean + bestParam[1]) + "," + (yMax - yMean + bestParam[2]) + 
		") and (" +
		(xMax - xMean + bestParam[5]) + "," + (yMax - yMean + bestParam[6]) + ")");
	showStatus("End of Correlations");
	showProgress(1);
	for (cntr = 0; cntr < n2D; cntr++) {
		roiImageData[cntr] += meanA;
	}
	//print("The best two-point fit occurs (in DG coordinates) for (" + bestParam[1] + ", "	+ bestParam[2] + ") and (" + bestParam[5] + ", " + bestParam[6] + ")");
	bestImageData = synthesizeDoubleGaussian(bestParam);
	compareData = Array.concat(roiImageData, bestImageData);
	plotImageArray(compareData);
	selectWindow("New Image");
	closeFitImageFlag = false;
	if (nResults > 0) {
		nResults_1 = nResults - 1;
		if (closeFitImageFlag) {
			run("Close");
		} else {
			rename("Cell "+getResult("Cell", nResults_1));
			wait(1);
			fitImageID = getImageID();
		}
		wait(1);
		setResult("Correlation", nResults_1, bestCorrelation);
	}
	if (isNaN(covCff)) {
		print("Correlation is NaN. VarA_ = " + VarA_ + " and VarB_ = " + VarB_);
	}
	
	//run("Set... ", "zoom=1000 x="+nXH+" y="+nYH);
	//select("ROI Manager");
	if (VarA_ == 0) {
		print("VarA_ = 0, roiImageTitle = " + roiImageTitle + ", roiID = " + roiID);
		wait(1);
		selectImage(roiID);
		wait(1);
		run("Enhance Contrast", "saturated=0.35");
		wait(1);
		bestParam = NaN;
	}
	plotCovFlag = false;
	if (plotCovFlag) {
		Array.getStatistics(AllCov, minCov, maxCov, meanCov, stdDevCov);
		Plot.create("Correlations", "Double-Gauss Index", "Correlation");
		Plot.setLimits(1, n2D, minCov, maxCov);
		Plot.setColor("blue");
		Plot.setLineWidth(2);
		Plot.add("line", AllCov);
		Plot.show();
		
		//print("Max of Correlation array = " + maxCov + ", Max found online = " + bestCorrelation); 
	
		//Array.print(AllCov);
		waitForUser("Please inspect the Correlation profile");
		wait(1);
		selectWindow("Correlations");
		wait(1);
		run("Close");
		wait(1);
	}
	return bestParam;
}

function displayOriginalandFit(roiID, tableIndex) {
	// imageP1Amp, imageP1x, imageP1y, imageP1Sigma2, imageP2Amp, imageP2x, imageP2y, imageP2Sigma2, nX, nY
	//nMaxima = getResult("n(Max)", tableIndex);
	nMaxima = 1;
	if (nMaxima != 1) {
		print("Wrong referral to displayOriginalandFit(roiID, tableIndex)");
		return NaN;
	}
	Amp1 = getResult("Amp1", tableIndex);
	X1 = getResult("cDGX1", tableIndex);
	Y1 = getResult("cDGY1", tableIndex);
	SigmaTwo1 = getResult("SigmaTwo1", tableIndex);
	Amp2 = getResult("Amp2", tableIndex);
	X2 = getResult("cDGX2", tableIndex);
	Y2 = getResult("cDGY2", tableIndex);
	SigmaTwo2 = getResult("SigmaTwo2", tableIndex);
	nX_ = getResult("nDGX", tableIndex);
	nY_ = getResult("nDGY", tableIndex);
	dgsParam = newArray(Amp1, X1, Y1, SigmaTwo1, Amp2, X2, Y2, SigmaTwo2, nX_, nY_);
	n2D = nX_ * nY_;
	xMean = floor( (nX_ - 1) / 2 );
	yMean = floor( (nY_ - 1) / 2 );
	
	selectImage(roiID);
	wait(10);
	dummy_1 = brightestSpot(roiID);
	xMax = dummy_1[0];
	yMax = dummy_1[1];
	iMax = dummy_1[2];
	//iMax = getPixel(xMax, yMax);
	
	roiImageData = newArray(n2D);
	Cntr = 0;
	for (y = 0; y < nY_; y++) {
		for (x = 0; x < nX_; x++) {
			//roiImageData[Cntr++] = getPixel(x,y);
			roiImageData[Cntr++] = getPixel(xMax - xMean + x, yMax - yMean +y);
		}
	}
	/*meanA = 0;
	for (cntr = 0; cntr < n2D; cntr++) {
		meanA += roiImageData[cntr];
	}
	meanA /= n2D;
	VarA_ = 0;
	for (cntr = 0; cntr < n2D; cntr++) {
		dummy_1 = roiImageData[cntr] - meanA;
		VarA_ += dummy_1 * dummy_1;
	}

	synthImageData = synthesizeDoubleGaussian(dgsParam);
	meanB = 0;
	for (cntr = 0; cntr < n2D; cntr++) {
		meanB += synthImageData[cntr];
	}
	meanB /= n2D;
	VarB_ = 0;
	VarAB_ = 0;
	for (cntr = 0; cntr < n2D; cntr++) {
		dummy_2 = synthImageData[cntr] - meanB;
		VarB_ += dummy_2 * dummy_2;
	}*/
	dgsImageData = synthesizeDoubleGaussian(dgsParam);
	compareData = Array.concat(roiImageData, dgsImageData);
	//Array.print(dgsImageData);Array.print(roiImageData);
	plotImageArray(compareData);
	compareImageID = getImageID();
	selectWindow("New Image");
	rename("Cell "+getResult("Cell", tableIndex));
	return compareImageID;
}


function Pearson(x,y) {
	return corrCoeff(x,y,true) / sqrt(corrCoeff(x,x,true) * corrCoeff(y,y,true));
}

function corrCoeff(x,y,CovFlag) {
	n = lengthOf(x);
	n2 = lengthOf(y);
	if (n != n2) {
		disp("Different lengths ("n+" and "+n2") are not allowed for correlation calculation.");
		crrCff = NaN;
	} else {
		if (CovFlag) {
			meanX = 0;
			meanY = 0;
			for (cntr = 0; cntr < n; cntr++) {
				meanX += x[cntr];
				meanY += y[cntr];
			}
			meanX /= n;
			meanY /= n;
			for (cntr = 0; cntr < n; cntr++) {
				x[cntr] -= meanX;
				y[cntr] -= meanY;
			}
		}
		crrCff = 0;
		for (cntr = 0; cntr < n; cntr++) {
			crrCff += x[cntr] * y[cntr];
		}
		crrCff /= n;
	}
	return crrCff;
}

function synthesizeDoubleGaussian(dgsParam) {
	//Array.print(dgsParam);
	
	imageP1Amp = dgsParam[0];
	imageP1x = dgsParam[1];
	imageP1y = dgsParam[2];
	imageP1Sigma2 = pow(dgsParam[3], 2);
	imageP2Amp = dgsParam[4];
	imageP2x = dgsParam[5];
	imageP2y = dgsParam[6];
	imageP2Sigma2 = pow(dgsParam[7], 2);
	nX = dgsParam[8];
	nY = dgsParam[9];
	nSingleROIImage = nX * nX;
	
	estimatedData = newArray(nSingleROIImage);
	Cntr = 0;
	for (y = 0; y < nY; y++) {
		for (x = 0; x < nX; x++) {
			estimatedData[Cntr++] = 
				imageP1Amp * exp(- (pow(x - imageP1x, 2) + pow(y - imageP1y, 2) ) / imageP1Sigma2 )
				+ 
				imageP2Amp * exp(- (pow(x - imageP2x, 2) + pow(y - imageP2y, 2) ) / imageP2Sigma2 )
			;
		}
	}
	return estimatedData;
}

function initializeROIResultsTable(newResultsTable) {
	run("Clear Results");
	updateResults();
	wait(1);
	setResult("Cell", 0, "");
	setResult("n(Max)", 0, "");
	setResult("Distance", 0, "");
	setResult("Correlation", 0, "");
	setResult("X1", 0, "");
	setResult("Y1", 0, "");
	setResult("X2", 0, "");
	setResult("Y2", 0, "");
	setResult("X3", 0, "");
	setResult("Y3", 0, "");
	setResult("Frame", 0, "");
	setResult("nDGX", 0, "");
	setResult("nDGY", 0, "");
	setResult("Amp1", 0, "");
	setResult("cDGX1", 0, "");
	setResult("cDGY1", 0, "");
	setResult("SigmaTwo1", 0, "");
	setResult("Amp2", 0, "");
	setResult("cDGX2", 0, "");
	setResult("cDGY2", 0, "");
	setResult("SigmaTwo2", 0, "");
	
	IJ.renameResults(newResultsTable);
	wait(1);
	run("Clear Results");
	updateResults();
	wait(1);
}

function preProcessCurrentStack(stackID, compositeFlag) {
	batchFlag = false;
	wait(1);
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

	//waitForUser(1);

	showStatus("Median Filtering");
	run("Median...", "radius=5 stack");

	//waitForUser(2);

	setAutoThreshold("Default dark stack");
	setThreshold(283, 2772);

	//waitForUser(3);
	
	run("Make Binary", "method=Default background=Default black");
	run("Watershed", "stack");

	//waitForUser(4);
	run("Voronoi", "stack");

	//waitForUser(5);
	
	run("8-bit");
	rename("Voronoi.tif");
	run("Macro...", "code=[v = 255* v / v] stack");
	run("Macro...", "code=[v = 255 - v] stack");
	run("Set Measurements...", "area perimeter fit shape stack redirect=None decimal=3");	
	run("Analyze Particles...", "  show=[Overlay Outlines] display clear include summarize add in_situ stack");
	run("Macro...", "code=[v = 255 - v] stack");
	run("Grays");
	run("16-bit");

	//waitForUser(6);
	

	run("Merge Channels...", "c1=C1-"+imageTitle+" c2=C2-"+imageTitle+" c3=Voronoi.tif create");
	if (batchFlag) {
	}
	//waitForUser(7);

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
		 	//print("Time-series interpreted as a stack");
		 } else {
		 	print("Hyperstack not allowed: nslices = " + nSlices_ + ", nFrames = " + nFrames_);
		 	newStackID = NaN;
		 }
	}
	run("Properties...", "slices="+nSlices_+" frames="+nFrames_);
	wait(1);
	if (compositeFlag) {
		Stack.setDisplayMode("composite");
	} else {
		Stack.setDisplayMode("color");
	}
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

function simulateHotSpots(dialogFlag) {
	imageID = 1;

	imageTitle = "Simulated double-spot";
	imageType = "32-bit";
	imageWidth = 19;
	imageHeight = 19;

	imageP1x = 8;
	imageP1y = 9;
	imageP1Amp = 0.5;
	imageP1Sigma = 4;

	imageP2x = 12;
	imageP2y = 6;
	imageP2Amp = 0.5;
	imageP2Sigma = 3;

	imageNoise = 0.2;

	if (dialogFlag) {
		Dialog.create("Parameters of the two-spot image");

		Dialog.addString("Title of the image", imageTitle);
		Dialog.addNumber("Width of the image", imageWidth);
		Dialog.addNumber("Height of the image", imageHeight);
		Dialog.addNumber("X coordinate of the first spot", imageP1x);
		Dialog.addNumber("Y coordinate of the first spot", imageP1y);
		Dialog.addNumber("Intensity of the first spot", imageP1Amp);
		Dialog.addNumber("Spread of the first spot", imageP1Sigma);
		Dialog.addNumber("X coordinate of the second spot", imageP2x);
		Dialog.addNumber("Y coordinate of the second spot", imageP2y);
		Dialog.addNumber("Intensity of the second spot", imageP2Amp);
		Dialog.addNumber("Spread of the second spot", imageP2Sigma);
		Dialog.addNumber("Intensity of noise", imageNoise);
	
		Dialog.show;
		
		imageTitle = Dialog.getString();
		imageWidth = Dialog.getNumber();
		imageHeight = Dialog.getNumber();
		imageP1x = Dialog.getNumber();
		imageP1y = Dialog.getNumber();
		imageP1Amp = Dialog.getNumber();
		imageP1Sigma = Dialog.getNumber();
		imageP2x = Dialog.getNumber();
		imageP2y = Dialog.getNumber();
		imageP2Amp = Dialog.getNumber();
		imageP2Sigma = Dialog.getNumber();
		imageNoise = Dialog.getNumber();
	}

	print("Simulated Centers: ("+imageP1x+", "+imageP1y+") and ("+imageP2x+", "+imageP2y+")");

	imageDepth = 1;
	imageNTotal = imageWidth * imageHeight;
	imageP1Sigma2 = pow(imageP1Sigma, 2);
	imageP2Sigma2 = pow(imageP2Sigma, 2);
	
	if (imageID > 0) {
		newImage(imageTitle, imageType, imageWidth, imageHeight, imageDepth);
		imageID = getImageID();
	}
	wait(1);
	selectImage(imageID);
	wait(1);

	imageData = newArray(imageNTotal);
	Cntr = 0;
	for (y = 0; y < imageHeight; y++) {
		for (x = 0; x < imageWidth; x++) {
			pixelIntensity = 
			imageP1Amp * exp(- (pow(x - imageP1x, 2) + pow(y - imageP1y, 2) ) / imageP1Sigma2 ) + 
			imageP2Amp * exp(- (pow(x - imageP2x, 2) + pow(y - imageP2y, 2) ) / imageP2Sigma2 ) + 
			imageNoise * random;
			setPixel(x,y,pixelIntensity);
			imageData[Cntr++] = pixelIntensity;
		}
	}
	//run("Surface Plot...", "polygon=100 shade draw_axis smooth");selectImage(imageID);
	nHx = floor(imageWidth / 2);
	nHy = floor(imageHeight / 2);
	run("Enhance Contrast", "saturated=0");
	run("Set... ", "zoom=800 x="+nHx+" y="+nHy);
	return imageID
}
	
function Initialize(closeFlag) {
  	print("\\Clear");
	wait(1);
  	roiManager("reset");
  	wait(10);
	//run("Collect Garbage");wait(10);
	if (closeFlag) {
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
	}
	run("Clear Results");
	updateResults();
	run("ROI Manager...");
	wait(1);
	tableFileExtension = "csv";
	run("Input/Output...", "jpeg=85 gif=-1 file="+tableFileExtension+" copy_column save_column");
}

function rasterScan(rsParam) {
	nRSParam = lengthOf(rsParam);
	if (nRSParam < 2) {
		print("Insufficient ("+nRSParam+") number of parameters as input to rasterScan(rsParam)");
		return NaN;
	} else {
		nX = parseInt(rsParam[0]);
		nY = parseInt(rsParam[1]);
		rasterFlag = false;
		normalizeFlag = false;
		plotFlag = false;
		if (nRSParam > 2) {
			rasterFlag = rsParam[2];
			if (nRSParam > 3) {
				normalizeFlag = rsParam[3];;
				if (nRSParam > 4) {
					plotFlag = rsParam[4];;
				}
			}
		}
	}
	n2D = nX * nY;
	C1 = nX / (PI/2);
	xMean = (nX - 1) / 2;
	yMean = (nY - 1) / 2;
	xFactor = (nX - 1) / 2;
	yFactor = (nY - 1) / 2;
	
	
	XY = newArray(n2D * 3);
	if (!normalizeFlag) {
		if (!rasterFlag) {
			for (cntr = 0; cntr < n2D; cntr++) {
				y = floor(cntr / nX);
				x = floor(C1 * asin(abs(sin(((cntr + 0.5) / C1)))));
				if (y != 2 * floor(y / 2)) {
					x =  (nX - 1 ) - x;
				}
				XY[cntr] = x;
				XY[cntr + n2D] = y;
			}
		} else {
			for (cntr = 0; cntr < n2D; cntr++) {
				XY[cntr] = floor(C1 * asin(abs(sin(((cntr + 0.5) / C1)))));
				XY[cntr + n2D] = floor(cntr / nX);
			}
		}
	} else {
		if (!rasterFlag) {
			for (cntr = 0; cntr < n2D; cntr++) {
				y = floor(cntr / nX);
				x = floor(C1 * asin(abs(sin(((cntr + 0.5) / C1)))));
				if (y != 2 * floor(y / 2)) {
					x =  (nX - 1 ) - x;
				}
				XY[cntr] = (x - xMean) / xFactor;
				XY[cntr + n2D] = (y - yMean) / yFactor;
			}
		} else {
			for (cntr = 0; cntr < n2D; cntr++) {
				XY[cntr] = (floor(C1 * asin(abs(sin(((cntr + 0.5) / C1))))) - xMean) / xFactor;
				XY[cntr + n2D] = (floor(cntr / nX) - yMean) / yFactor;
			}
		}
	}

	if (plotFlag) {
		newImage("X", "32-bit black", nX, nY, 1);
		Cntr = 0;
		for (y = 0; y < nY; y++) {
			for (x = 0; x < nX; x++) {
				setPixel(x, y, XY[Cntr++]);
			}
		}
		run("Enhance Contrast", "saturated=0");
		
		newImage("Y", "32-bit black", nX, nY, 1);
		Cntr = 0;
		for (y = 0; y < nY; y++) {
			for (x = 0; x < nX; x++) {
				setPixel(x, y, XY[n2D + Cntr]);
				Cntr++;
			}
		}
		run("Enhance Contrast", "saturated=0");
	}
	return XY;
}

function plotImageArray(imageArray) {
	n1D = sqrt(lengthOf(imageArray));
	if (n1D != round(n1D)) {
		n1D = sqrt(lengthOf(imageArray) / 2);
		if (n1D != round(n1D)) {
			print("Input array corresponds to a non-square 2D pattern.");
			return NaN;
		}
		twoImageFlag = true;
		n2D = pow(n1D, 2);
		imageArray1 = Array.slice(imageArray, 0, n2D);
		imageArray2 = Array.slice(imageArray, n2D, 2 * n2D);
		nOffset = maxOf(10, floor(0.20 * n1D));
		nX_ = 2 * n1D + nOffset;
		newImage("New Image", "32-bit black", nX_, n1D, 1);
		Array.getStatistics(imageArray1, min1, max1, mean1, stdDev1);
		Array.getStatistics(imageArray2, min2, max2, mean2, stdDev2);
		for (cntr = 0; cntr < n2D; cntr++) {
			dummy_1 = (imageArray1[cntr] - mean1) / stdDev1;
			imageArray2[cntr] = mean1 + (stdDev1 / stdDev2) * (imageArray2[cntr] - mean2);
		}
		Gain = 255;
		Cntr = 0;
		for (y = 0; y < n1D; y++) {
			for (x = 0; x < n1D; x++) {
				setPixel(x, y, imageArray1[Cntr]);
				setPixel(x + n1D + nOffset, y, imageArray2[Cntr++]);
			}
			for (x = 0; x < nOffset; x++) {
				setPixel(x + n1D, y, max1);
			}
		}
	} else {
		twoImageFlag = false;
		newImage("New Image", "32-bit black", n1D, n1D, 1);
		Cntr = 0;
		for (y = 0; y < n1D; y++) {
			for (x = 0; x < n1D; x++) {
				setPixel(x, y, imageArray[Cntr++]);
			}
		}
		nX_ = n1D;
	}
	run("Enhance Contrast", "saturated=0.");
	nH = floor(n1D / 2);
	run("Set... ", "zoom=800 x="+nH+" y="+nH);
	return getImageID;
}

function plotRasteredImageArray(imageArray) {
	n1D = sqrt(lengthOf(imageArray));
	if (n1D != round(n1D)) {
		print("Input array corresponds to a non-square 2D pattern.");
		return NaN;
	}
	imageTitle = "New Image";
	if(isOpen(imageTitle)) {
		wait(1);
		selectWindow(imageTitle);
		wait(10);
		run("Close");
		wait(10);
	}
	newImage("New Image", "32-bit black", n1D, n1D, 1);
	Cntr = 0;
	for (y = 0; y < n1D; y++) {
		if (y == 2 * floor(y / 2)) {
			for (x = 0; x < n1D; x++) {
				setPixel(x, y, imageArray[Cntr++]);
			}
		} else {
			for (x = 0; x < n1D; x++) {
				setPixel(n1D -1 - x, y, imageArray[Cntr++]);
			}
		}
	}
	run("Enhance Contrast", "saturated=0.");
	nH = floor(n1D / 2);
	run("Set... ", "zoom=800 x="+nH+" y="+nH);
	return getImageID;
}

function brightestSpot(imageID) {
	wait(1);
	selectImage(imageID);
	wait(20);
	nX = getWidth;
	nY = getHeight;
	n2D = nX * nY;
	xMax = 0;
	yMax = 0;
	valueMax = - 1e100;
	for (y = 0; y < nY; y++) {
		for (x = 0; x < nX; x++) {
			dummy_1 = getPixel(x, y);
			if (valueMax < dummy_1) {
				valueMax = dummy_1;
				xMax = x;
				yMax = y;
			}
		}
	}
	return newArray(xMax, yMax, valueMax);
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

function loadTable() {
	run("Set Measurements...", "redirect=None decimal=1");
	if (isOpen("Results") == false) {
		//run("Results");
	}
	updateResults();
	wait(1);
	if (nResults != 0) {
		print("The Results Table is not empty.");
		run("Clear Results");
		updateResults();
		wait(1);
	}
	updateResults();
	wait(1);
	selectWindow("Results");
	wait(1);
	filePath = File.openDialog("Select the ROI File");
	wait(1);
	if (endsWith(filePath, "csv")) {
		tableFileExtension = "csv";
	} else if (endsWith(filePath, "txt")) {
		tableFileExtension = "txt";
	} else {
		tableFileExtension = "txt";
	}
	print("filePath = "+filePath);
	wait(1);
	run("Results... ","open="+"["+filePath+"]");
	wait(1);
	//waitForUser;
	updateResults();
	wait(1);
	print("nResults = "+nResults);
	wait(1);
	selectWindow("Results");
	wait(1);
	outputFlag = true;
	return outputFlag;
}

function cell2TableIndex(n) {
	nPlus = ++n;
	nTable = 0;
	nResults_1 = nResults - 1;
	continueFlag = true;
	while (continueFlag) {
		if (getResult("Cell", nTable) == nPlus) {
			continueFlag = false;
		} else {
			if (nTable == nResults_1) {
				continueFlag = false;
				nTable = NaN;
				print("No match between cell number and ROI entries found.");
			}
			nTable++;
		}			
	}
	return nTable;
}



	