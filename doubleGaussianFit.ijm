// Program: doubleGaussianFit.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Retrieves the distance between two assumed spots by fitting a two-Gaussian function. A priori knowledge about the sizes and (relative) intensities of the spots can be used to minimize the dimensionality of the problem. The measure of similarity is Pearson's correlation coefficient.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	dialogFlag = false;

	//Known spaot parameters
	Amp1 = 1;
	SigmaTwo1 = 3;
	Amp2 = 1;
	SigmaTwo2 = 3;

	simulateFlag = decideDataType();
	if (simulateFlag) {
		hotSpotsImageID = simulateHotSpots(dialogFlag);
	} else {
		waitForUser("Please edit the code to introduce your input image.");
		wait(1),
		return 0;
	}
	nDGX = 15;	//Width of the ROI
	nDGY = 15;	//Height of the ROI


	//Parameterizing (the unknown positions and the known widths/intensities of) a double-Gaussian profile
	fdgParam_in = newArray(Amp1, NaN, NaN, SigmaTwo1, Amp2, NaN, NaN, SigmaTwo2, nDGX, nDGY);
	//print("Input parameters of the fit program:");Array.print(fdgParam_in);
	fdgParam = fitDoubleGaussian(hotSpotsImageID, fdgParam_in);
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
	//print("ROI image center on the original image xMax = " + xMax + ", yMax = " + yMax);
	
	// imageP1Amp, imageP1x, imageP1y, imageP1Sigma2, imageP2Amp, imageP2x, imageP2y, imageP2Sigma2, nX, nY
	// dgsParam[0], dgsParam[1], dgsParam[2], dgsParam[3], dgsParam[4], dgsParam[5], dgsParam[6], dgsParam[7], dgsParam[8], dgsParam[9] 
	sigmaMin = sqrt(2);
	sigmaMax = maxOf(2, floor(sqrt(minOf(nX_,nY_) / 2)));
	sigma0 = 3;
	nXH = floor(nX_ / 2);
	nYH = floor(nY_ / 2);

	showStatus("Calculating Correlations ...");

	dgsMin = newArray(Amp1, 0, 0, sigmaMin, 0.1, 0, 0, sqrt(2), nX_, nY_);
	dgsMax = newArray(Amp1, nX_ - 1, nY_ - 1 , sigmaMax, 0.9, nX_ - 1, nY_ - 1, sigmaMax, nX_, nY_);
	dgsN = newArray(1, nX_, nY_, 1, 1, nX_, nY_, 1, 1, 1);
	dgsDefault = newArray(Amp1, nXH, nYH, sigma0, Amp2, nXH, nYH, sigma0, nX_, nY_);

	ndgsParam = lengthOf(dgsDefault);
	nParamSet = 1;
	dgsStep = newArray(ndgsParam);
	dgsScanFlag = newArray(ndgsParam);
	for (cntr = 0; cntr < ndgsParam; cntr++) {
		if (dgsN[cntr] > 1) {
			dgsScanFlag[cntr] = true;
			dgsStep[cntr] = (dgsMax[cntr] - dgsMin[cntr]) / (dgsN[cntr] - 1);
			nParamSet *= dgsN[cntr];
		} else {
			dgsScanFlag[cntr] = false;
			dgsMin[cntr] = dgsDefault[cntr];
			dgsMax[cntr] = dgsDefault[cntr];
			dgsStep[cntr] = 1;
		}
	}


	//Scanning (global search for) all parameters of a double-Gaussian
	// Removing the degeneracy of (symmetric) spots
	// Enforcing the spots to be confined within the domain

	nParamSet_ = nParamSet / 11;	//11: Empirical factor (to be estimated more accurately)
									//nParamSet includes degenerate cases and those with spots on boundaries
	
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
				dgsParam = newArray(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9);
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
				 	bestCorrelation = covCff;
				 	bestParam = dgsParam;
				}
				AllCov[Counter] = covCff;
				showProgress(Counter++, nParamSet_);
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

	//dgParam = newArray(bestParam[1], bestParam[2], bestParam[5], bestParam[6]);
	print("Best Double-Gaussian Centers in original coordinate: (" + 
		(xMax - xMean + bestParam[1]) + "," + (yMax - yMean + bestParam[2]) + 
		") and (" +
		(xMax - xMean + bestParam[5]) + "," + (yMax - yMean + bestParam[6]) + ")");
	print("Best Double-Gaussian Centers in ROI coordinate: (" + 
		(bestParam[1]) + "," + (bestParam[2]) + 
		") and (" +
		(bestParam[5]) + "," + (bestParam[6]) + ")");
	showStatus("End of Correlations");
	showProgress(1);
	for (cntr = 0; cntr < n2D; cntr++) {
		roiImageData[cntr] += meanA;
	}
	bestImageData = synthesizeDoubleGaussian(bestParam);
	compareData = Array.concat(roiImageData, bestImageData);

	plotImageArray(compareData);

	selectWindow("New Image");
	if (isNaN(covCff)) {
		print("Correlation is NaN. VarA_ = " + VarA_ + " and VarB_ = " + VarB_);
	}
	if (VarA_ == 0) {
		print("VarA_ = 0, roiImageTitle = " + roiImageTitle + ", roiID = " + roiID);
		wait(1);
		selectImage(roiID);
		wait(1);
		run("Enhance Contrast", "saturated=0.35");
		wait(1);
		bestParam = NaN;
	}
	return bestParam;
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

function simulateHotSpots(dialogFlag) {
	imageID = 1;

	imageTitle = "Simulated double-spot";
	imageType = "32-bit";
	imageWidth = 40;
	imageHeight = 40;

	imageP1x = 19;
	imageP1y = 17;
	imageP1Amp = 0.5;
	imageP1Sigma = 4; 

	imageP2x = 22;
	imageP2y = 14;
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

	print("Simulated Centers in the original coordinate: ("+imageP1x+", "+imageP1y+") and ("+imageP2x+", "+imageP2y+")");

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
	
function Initialize() {
  	print("\\Clear");
	wait(1);
  	roiManager("reset");
  	wait(10);
	//run("Collect Garbage");wait(10);
	setBatchMode("exit and display");
	setBatchMode(false);
	wait(200);
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
	run("Clear Results");
	updateResults();
	run("ROI Manager...");
	wait(1);
	tableFileExtension = "csv";
	run("Input/Output...", "jpeg=85 gif=-1 file="+tableFileExtension+" copy_column save_column");
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

		imageArray2 = Array.slice(imageArray, 1 * n2D, 2 * n2D);
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

function decideDataType() {
	items = newArray("Simulate data", "Load data");
	Dialog.create("Double-spot image");
	Dialog.addRadioButtonGroup("Source of data", items, 2, 1, items[0]);
	Dialog.show();
	if (Dialog.getRadioButton() == items[0]) {
		simulateFlag = true;
	} else {
		simulateFlag = false;
	}
	return simulateFlag;
}

	