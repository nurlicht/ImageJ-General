// Program: trackGenerate.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Helps with validation of tracking results. The program simulates time-lapse microscopy images of a particle along a gievn track. The size, the orientation, and the brightness of the particle can change over time. This code offers a convenient starting point to introduce more realistic changes to the particle, as studied in the population context and cell morphology.   

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	trackParams = getTrackParams();
	Orientation = evaluateOrientations(trackParams);
	Intensity = evaluateIntensities(trackParams);
	DxDy = evaluateDiameters(trackParams);
	XY = evaluateCenters(trackParams);
	evolveParticle(trackParams, Orientation, Intensity, DxDy, XY);
}

function Initialize() {
	print("\\Clear");

  	setBatchMode("exit and display");
  	wait(100);
	if (nImages > 0) {
		run("Close All");
		while (nImages > 0) {
		}
		wait(1);
	}
  	setBatchMode(true);
  	wait(10);

	if (nResults > 0) {
		run("Clear Results");
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	wait(1);
}

function evaluateOrientations(trackParams) {
	orientationModulation = trackParams[3];
	nT = trackParams[7];
	Orientation = newArray(nT);
	for (cntr = 0; cntr < nT; cntr++) {
		if (toLowerCase(orientationModulation) == "linear") {
			thetaMax = 180 / 2;
			Orientation[cntr] = (cntr / nT) * thetaMax;
		} else if (toLowerCase(orientationModulation) == "sinusoidal") {
			thetaMax = 180 * 2;
			Orientation[cntr] = thetaMax * sin((cntr / nT) * thetaMax * PI / 180);
		} else {
			Orientation[cntr] = 0;
		}
	}
	return Orientation;
}

function evaluateIntensities(trackParams) {
	intensityModulation = trackParams[4];
	nT = trackParams[7];
	noiseLevel = trackParams[10];
	Intensity = newArray(nT);
	for (cntr = 0; cntr < nT; cntr++) {
		if (toLowerCase(intensityModulation) == "linear") {
			iMax = 0xff - noiseLevel;
			Intensity[cntr] = floor((cntr / nT) * iMax + noiseLevel * random);
		} else if (toLowerCase(intensityModulation) == "sinusoidal") {
			iMaxModNorm = 0.50;
			iMax = 0xff * (1 - iMaxModNorm) - noiseLevel;
			thetaMax = 2 * PI;
			Intensity[cntr] = floor(iMax * (1 + iMaxModNorm * sin((cntr / nT) * thetaMax)) + noiseLevel * random);
		} else {
			Intensity[cntr] = 0xff - noiseLevel + noiseLevel * random;
		}
		Intensity[cntr] = maxOf(0, minOf(0xff, Intensity[cntr]));
	}
	return Intensity;
}

function evaluateDiameters(trackParams) {
	sizeModulation = trackParams[2];
	nT = trackParams[7];
	xDiameter = trackParams[8];
	yDiameter = trackParams[9];
	xDiameterHalf = floor(xDiameter / 2);
	yDiameterHalf = floor(yDiameter / 2);
	Dx = newArray(nT);
	Dy = newArray(nT);
	for (cntr = 0; cntr < nT; cntr++) {
		if (toLowerCase(sizeModulation) == "linear") {
			xDiameterModNorm = 0.50;
			yDiameterModNorm = 0.50;
			Dx[cntr] = xDiameter + floor((cntr / nT) * xDiameterModNorm * xDiameter);
			Dy[cntr] = yDiameter + floor((cntr / nT) * yDiameterModNorm * yDiameter);
		} else if (toLowerCase(sizeModulation) == "sinusoidal") {
			xDiameterModNorm = 0.50;
			yDiameterModNorm = 0.50;
			thetaMax = PI * 2;
			Dx[cntr] = xDiameter + floor(xDiameterModNorm * xDiameter * sin((cntr / nT) * thetaMax));
			Dy[cntr] = yDiameter + floor(yDiameterModNorm * yDiameter * sin((cntr / nT) * thetaMax));
			
		} else {
			Dx[cntr] = xDiameter;
			Dy[cntr] = yDiameter;
		}
	}
	DxDy = Array.concat(Dx, Dy);
	return 	DxDy;
}

function evaluateCenters(trackParams) {
	trackType = trackParams[0];
	nX = trackParams[5];
	nY = trackParams[6];
	nT = trackParams[7];
	xDiameter = trackParams[8];
	yDiameter = trackParams[9];
	nXHalf = floor(nX / 2) - maxOf(xDiameter, yDiameter) / 2;
	nYHalf = floor(nY / 2) - maxOf(xDiameter, yDiameter) / 2;
	xDiameterHalf = floor(xDiameter) / 2;
	yDiameterHalf = floor(yDiameter) / 2;
	x = newArray(nT);
	y = newArray(nT);
	if (toLowerCase(trackType) == "random") {
		xMin = 0;
		xMax = nX - 1;
		x[0] = floor(nX / 2);
		dx = maxOf(1, floor(nX * 0.10));
		
		yMin = xMin;
		yMax = xMax;
		y[0] = x[0];
		dy = dx;

		for (cntr = 1; cntr < nT; cntr++) {
			x_ = x[cntr - 1] + floor(dx * 2 * (random - 0.5));
			x_ = maxOf(x_, xMin);
			x_ = minOf(x_, xMax);
			x[cntr] = x_;
	
			y_ = y[cntr - 1] + floor(dy * 2 * (random - 0.5)); 
			y_ = maxOf(y_, yMin);
			y_ = minOf(y_, yMax);
			y[cntr] = y_;
		}
	} else if (toLowerCase(trackType) == "chaotic") {
		thetaMax = (1 * PI);
		rMax = floor(minOf(nX, nY) - maxOf(xDiameter, yDiameter));
		x[0] = - 0.72;
		y[0] = - 0.64;
		a = 0.9;
		b = - 0.6013;
		c = 2.0;
		d = 0.50;
		for (cntr = 1; cntr < nT; cntr++) {
			x[cntr] = pow(x[cntr - 1], 2) - pow(y[cntr - 1], 2) + a * x[cntr - 1] + b * y[cntr - 1];
			y[cntr] = 2 * x[cntr - 1] * y[cntr - 1] + c * x[cntr - 1] + d * y[cntr - 1];
		}
		for (cntr = 0; cntr < nT; cntr++) {
			x[cntr] = floor((rMax / 1.5) * (x[cntr] + 1.3));
			y[cntr] = floor((rMax / 2.1) * (y[cntr] + 1.5));
			print("cntr = " + cntr + ", x = " + x[cntr] + ", y = " + y[cntr]);
		}
	} else if (toLowerCase(trackType) == "folium") {
		thetaMax = (1 * PI);
		rMax = floor(minOf(nX, nY) / 2 - maxOf(xDiameter, yDiameter) / 2);
		for (cntr = 0; cntr < nT; cntr++) {
			Theta = (cntr / nT) * thetaMax - PI / 4;
			a = 2 / 5;
			s = sin(Theta);
			c = cos(Theta);
			R = rMax * 1.5 * s * c / (pow(s, 3) + pow(c, 3));
			x[cntr] = nXHalf + floor(R * cos(Theta)) + xDiameterHalf;
			y[cntr] = nYHalf + floor(R * sin(Theta)) + yDiameterHalf;
		}
	} else if (toLowerCase(trackType) == "spiral") {
		thetaMax = (4 * PI);
		rMax = floor(minOf(nX, nY) / 2 - maxOf(xDiameter, yDiameter) / 2);
		for (cntr = 0; cntr < nT; cntr++) {
			Theta = (cntr / nT) * thetaMax;
			R = rMax * (Theta / thetaMax);
			x[cntr] = nXHalf + floor(R * cos(Theta)) + xDiameterHalf;
			y[cntr] = nYHalf + floor(R * sin(Theta)) + yDiameterHalf;
		}
		
	} else if (toLowerCase(trackType) == "butterfly") {
		thetaMax = (4 * PI);
		rMax = floor(minOf(nX, nY) / 2 - maxOf(xDiameter, yDiameter) / 2);
		for (cntr = 0; cntr < nT; cntr++) {
			Theta = (cntr / nT) * thetaMax;
			R = rMax * (
					exp(sin(Theta)) - 2 * cos(4 * Theta) + pow(sin(Theta / 12  - PI / 24), 5)
				);
			x[cntr] = nXHalf + floor(R * cos(Theta) / 2)  + xDiameterHalf;
			y[cntr] = nYHalf + floor(R * sin(Theta) / 2)  + yDiameterHalf;
		}
		
	} else if (toLowerCase(trackType) == "lissajous") {
		a = 3;
		b = 2;
		thetaMax = (2 * PI);
		rMax = floor(minOf(nX, nY) / 2 - maxOf(xDiameter, yDiameter) / 2);
		for (cntr = 0; cntr < nT; cntr++) {
			Theta = (cntr / nT) * thetaMax;
			x[cntr] = nXHalf + floor(rMax * cos(a * Theta)) + xDiameterHalf;
			y[cntr] = nYHalf + floor(rMax * sin(b * Theta)) + yDiameterHalf;
		}
		
	} else if (toLowerCase(trackType) == "rhodonea") {
		thetaMax = (5 * PI);
		rMax = floor(minOf(nX, nY) / 2 - maxOf(xDiameter, yDiameter) / 2);
		for (cntr = 0; cntr < nT; cntr++) {
			Theta = (cntr / nT) * thetaMax;
			c = 2 / 5;
			R = rMax * sin(c * Theta);
			x[cntr] = nXHalf + floor(R * cos(Theta)) + xDiameterHalf;
			y[cntr] = nYHalf + floor(R * sin(Theta)) + yDiameterHalf;
		}
	}
	XY = Array.concat(x, y);
	return 	XY;
}

function evolveParticle(trackParams, Orientation, Intensity, DxDy, XY) {
	particleShapeType = trackParams[1];
	nX = trackParams[5];
	nY = trackParams[6];
	nT = trackParams[7];
	x = Array.slice(XY, 0 * nT, 1 * nT);
	y = Array.slice(XY, 1 * nT, 2 * nT);
	Dx = Array.slice(DxDy, 0 * nT, 1 * nT);
	Dy = Array.slice(DxDy, 1 * nT, 2 * nT);

	setBatchMode(true);
	for (cntr = 0; cntr < nT; cntr++) {
		generateSpot(particleShapeType, Orientation[cntr], Intensity[cntr], x[cntr], y[cntr], Dx[cntr], Dy[cntr], nX, nY, cntr);
	}
	wait(1);
	run("Images to Stack", "name=Stack title=[] use");
	run("8-bit");
	run("Enhance Contrast", "saturated=0");
	stackID = getImageID;
	//run("Set... ", "zoom=400 x=" + getWidth + " y=" + getHeight);
	setBatchMode("exit and display");
  	wait(1);

	run("Z Project...", "projection=[Max Intensity]");

	selectImage(stackID);
	run("Duplicate...", "duplicate");
	run("Macro...", "code=[v = floor(1 + v * (z/" + (nT + 1) + "))] stack");
	run("Cyan");
	run("Z Project...", "projection=[Max Intensity]");
	
	
	correlationAnalysisFlag = false;
	if (correlationAnalysisFlag) {
		t = newArray(nT);
		for (cntr = 0; cntr < nT; cntr++) {
			t[cntr] = cntr + 1;
		}
		correlationAnalysis(x, y, t);
	  	wait(1);
	}
	return true;
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

function synthesize2DPath(nT, nX) {
	x = newArray(nT);
	y = newArray(nT);
	t = newArray(nT);

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
	
	for (cntr = 1; cntr < nT; cntr++) {
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
		fraction = round(255 * cntr / (nT - 1));
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

function getTrackParams() {
	typeItems = newArray("Random", "Chaotic", "Spiral", "Folium", "Butterfly", "Lissajous","Rhodonea");
	particleShapeItems = newArray("Oval", "Rectangular");
	sizeModItems = newArray("None", "Linear", "Sinusoidal");
	orientationModItems = newArray("None", "Linear", "Sinusoidal");
	intensityModItems = newArray("None", "Linear", "Sinusoidal");
	nX = 150;
	nY = nX;
	nT = 100;
	xDiameter = 10;
	yDiameter = 6;
	noiseLevel = 10;

	nTrackParams = 11;

	smallGUIFlag = getBoolean("Choosing only track types?");

	Dialog.create("Track Parameters");
	Dialog.addRadioButtonGroup("Type", typeItems, lengthOf(typeItems), 1, typeItems[0]);
	if (!smallGUIFlag) {
		Dialog.addRadioButtonGroup("Particle Shape", particleShapeItems, lengthOf(particleShapeItems), 1, particleShapeItems[0]);
		Dialog.addRadioButtonGroup("Size Modulation", sizeModItems, lengthOf(sizeModItems), 1, sizeModItems[0]);
		Dialog.addRadioButtonGroup("Orientation Modulation", orientationModItems, lengthOf(orientationModItems), 1, orientationModItems[0]);
		Dialog.addRadioButtonGroup("Intensity Modulation", intensityModItems, lengthOf(intensityModItems), 1, intensityModItems[0]);
		Dialog.addNumber("Image Width", nX);
		Dialog.addNumber("Image Height", nY);
		Dialog.addNumber("Time Span", nT);
		Dialog.addNumber("Particle Width", xDiameter);
		Dialog.addNumber("Particle Height", yDiameter);
		Dialog.addNumber("Noise Level", noiseLevel);
	}
	Dialog.show();

	trackParams = newArray(nTrackParams);
	trackParams[0] = Dialog.getRadioButton();
	if (!smallGUIFlag) {
		trackParams[1] = Dialog.getRadioButton();
		trackParams[2] = Dialog.getRadioButton();
		trackParams[3] = Dialog.getRadioButton();
		trackParams[4] = Dialog.getRadioButton();
		trackParams[5] = parseInt(Dialog.getNumber());
		trackParams[6] = parseInt(Dialog.getNumber());
		trackParams[7] = parseInt(Dialog.getNumber());
		trackParams[8] = parseInt(Dialog.getNumber());
		trackParams[9] = parseInt(Dialog.getNumber());
		trackParams[10] = parseInt(Dialog.getNumber());
	} else {
		trackParams[1] = particleShapeItems[0];
		trackParams[2] = sizeModItems[0];
		trackParams[3] = orientationModItems[0];
		trackParams[4] = intensityModItems[0];
		trackParams[5] = nX;
		trackParams[6] = nY;
		trackParams[7] = nT;
		trackParams[8] = xDiameter;
		trackParams[9] = yDiameter;
		trackParams[10] = noiseLevel;
	}

	return trackParams;
}

function createStack(trackParams) {
	imageTitle = "Tracking_Time_Lapse";
	imageType = "32-bit black";
	nX = trackParams[5];
	nY = trackParams[6];
	nT = trackParams[7];
	newImage(title, type, nX, nY, nT);
	while (!isOpen(imageTitle)) {
	}
	wait(1);
	return imageTitle;
}

function generateSpot(Shape, Orientation, Intensity, x, y, Dx, Dy, nX, nY, Cntr) {
	DxHalf = round(Dx / 2);
	DyHalf = round(Dy / 2);

	tempImageTitle = "Frame_" + Cntr;
	newImage(tempImageTitle, "RGB black", nX, nX, 1);
	while (!isOpen(tempImageTitle)) {
	}
	if (toLowerCase(Shape) == "oval") {
		makeOval(x - DxHalf, y - DyHalf, Dx, Dy);
	} else if (toLowerCase(Shape) == "rectangular") {
		makeRectangle(x - DxHalf, y - DyHalf, Dx, Dy);
	} else {
		waitForUser("Wrong type of particle shape!");
		return -1;
	}

	run("Rotate...", "  angle=" + Orientation);

	if (Intensity != round(Intensity)) {
		Intensity = round(Intensity);
		//print("Intensity was rounded.");
	}
	if (Intensity > 255) {
		Intensity = 255;
		print("Intensity was clipped at 255.");
	}
	if (Intensity < 0) {
		Intensity = 0;
		print("Intensity was clipped at 0.");
	}
	Intensity = toHex(Intensity);
	if (lengthOf(Intensity) < 2) {
		Intensity = "0" + Intensity;
	}
	color = Intensity + Intensity + Intensity;
	Overlay.addSelection("", 0 ,"#" + color);
	Overlay.show();
	run("Select None");
	run("Flatten");
	close(tempImageTitle);
	//wait(1);
}

