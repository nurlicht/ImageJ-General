// Program: focusPattern.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Generates the 3D profile of a focused beam. With the two parameters of wavelenght ("channel") and focusing level ("frame"), the entire data is generated as a 5D hyperstack.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	beamParameters = getBeamParameters();
	lightData = getLightDistribution(beamParameters);
	imageTitle = createStack(beamParameters);
	displayObject(lightData, beamParameters, imageTitle);
	makeImagesVisible();
}

function makeImagesVisible() {
  	setBatchMode("exit and display");
  	setBatchMode(false);
  	wait(1);
	
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

  	setBatchMode(true);
  	wait(100);

}

function displayObject(lightData, beamParameters, imageTitle) {
	nX = beamParameters[0];
	nY = beamParameters[1];
	nZ= beamParameters[2];
	nT= beamParameters[3];
	Lambda1_nm= beamParameters[4];
	Lambda2_nm = beamParameters[5];
	nC = beamParameters[6];
	w0_min_nm = beamParameters[7];
	w0_max_nm = beamParameters[8];
	rMax_nm = beamParameters[9];
	zMax_nm = beamParameters[10];

	n5D = nX * nY * nZ * nT * nC;
	selectWindow(imageTitle);
	wait(1);
	Stack.getDimensions(imageWidth, imageHeight, imageSlices, imageFrames, imageChannels);	
	showStatus("Setting pixel values ...");
	Cntr = 0;
	for (c = 0; c < nC; c++) {
		for (t = 0; t < nT; t++) {
			for (z = 0; z < nZ; z++) {
				Stack.setPosition(1 + c, 1 + z, 1 + t);
				for (y = 0; y < nY; y++) {
					for (x = 0; x < nX; x++) {
						setPixel(x, y, lightData[Cntr++]);
					}
				}
				showProgress(Cntr, n5D);
			}
		}
	}
	return true;
}

function getLightDistribution(beamParameters) {
	nX = beamParameters[0];
	nY = beamParameters[1];
	nZ= beamParameters[2];
	nT= beamParameters[3];
	Lambda1_nm= beamParameters[4];
	Lambda2_nm = beamParameters[5];
	nC = beamParameters[6];
	w0_min_nm = beamParameters[7];
	w0_max_nm = beamParameters[8];
	rMax_nm = beamParameters[9];
	zMax_nm = beamParameters[10];

	Lambda_nm_Vector = newArray(nC);
	for (cntr = 0; cntr < nC; cntr++) {
		Lambda_nm_Vector[cntr] = Lambda1_nm + cntr * (Lambda2_nm - Lambda1_nm) / (nC - 1);
	}

	w0_nm_Vector = newArray(nT);
	for (cntr = 0; cntr < nT; cntr++) {
		w0_nm_Vector[cntr] = w0_min_nm + cntr * (w0_max_nm - w0_min_nm) / (nT - 1);
	}

	showStatus("Creating the data array ...");
	n5D = nX * nY * nZ * nT * nC;
	lightData = newArray(n5D);

	showStatus("Calculating pixel values ...");
	I0 = 255;
	Cntr = 0;
	for (c = 0; c < nC; c++) {
		Lambda_nm = Lambda_nm_Vector[nC - c - 1];
		for (t = 0; t < nT; t++) {
			w0_nm = w0_nm_Vector[t];
			zR_nm = PI * pow(w0_nm, 2) / Lambda_nm;
			for (z = 0; z < nZ; z++) {
				Z = zMax_nm * (z / (nZ / 2) - 1);
				w_z_nm = w0_nm * sqrt(1 + pow(Z / zR_nm, 2));
				twoOverWz2 = 2 / pow(w_z_nm, 2);
				for (y = 0; y < nY; y++) {
					Y = rMax_nm * (y / (nY / 2) - 1);
					for (x = 0; x < nX; x++) {
						X = rMax_nm * (x / (nX / 2) - 1);
						lightData[Cntr++] = floor(I0 * pow(w0_nm/w_z_nm, 2) * exp(-(X*X + Y*Y) * twoOverWz2));
					}
				}
				showProgress(Cntr, n5D);
			}
		}
	}
	showStatus(" ");
	return 	lightData;
}

function getBeamParameters() {
	nX = 100;
	nY = 100;
	nZ = 100;
	nT = 4;
	nC = 2;
	Lambda1_nm = 400;
	Lambda2_nm = 700;

	nParams = 11;

	url = "https://en.wikipedia.org/wiki/Gaussian_beam";

	Dialog.create("Focus Parameters");
	Dialog.addNumber("Image Width", nX);
	Dialog.addNumber("Image Height", nY);
	Dialog.addNumber("Image Depth", nZ);
	Dialog.addNumber("Number of Focus Levels", nT);
	Dialog.addNumber("First Wavelength (nm)", Lambda1_nm);
	Dialog.addNumber("Second Wavelength (nm)", Lambda2_nm);
	Dialog.addNumber("Number of Wavelengths", nC);
	Dialog.addHelp(url); 
	Dialog.show();

	beamParameters = newArray(nParams);
	nX = parseInt(Dialog.getNumber());
	nY = parseInt(Dialog.getNumber());
	nZ = parseInt(Dialog.getNumber());
	nT = parseInt(Dialog.getNumber());
	Lambda1_nm = parseInt(Dialog.getNumber());
	Lambda2_nm = parseInt(Dialog.getNumber());
	nC = parseInt(Dialog.getNumber());

	//Sorting wavelengths
	if (Lambda2_nm < Lambda1_nm) {
		tempData = Lambda2_nm;
		Lambda2_nm = Lambda1_nm;
		Lambda1_nm = tempData;
	}
	
	NA = 1.4;
	w0_min_nm = Lambda1_nm / (2 * NA);
	w0_max_nm = 2 * Lambda2_nm / (2 * NA);
	rMax_nm = 0.75 * w0_max_nm;
	zMax_nm = PI * pow(w0_max_nm, 2) / Lambda2_nm;
	
	beamParameters[0] = nX;
	beamParameters[1] = nY;
	beamParameters[2] = nZ;
	beamParameters[3] = nT;
	beamParameters[4] = Lambda1_nm;
	beamParameters[5] = Lambda2_nm;
	beamParameters[6] = nC;
	beamParameters[7] = w0_min_nm;
	beamParameters[8] = w0_max_nm;
	beamParameters[9] = rMax_nm;
	beamParameters[10] = zMax_nm;

	return beamParameters;
}

function createStack(beamParameters) {
	nX = beamParameters[0];
	nY = beamParameters[1];
	nZ= beamParameters[2];
	nT= beamParameters[3];
	Lambda1_nm= beamParameters[4];
	Lambda2_nm = beamParameters[5];
	nC = beamParameters[6];
	w0_min_nm = beamParameters[7];
	w0_max_nm = beamParameters[8];
	rMax_nm = beamParameters[9];
	zMax_nm = beamParameters[10];

	imageTitle = "Hyperstack";
	run("New HyperStack...", "title=[" + imageTitle + "] type=[8-bit black] width=" + nX + " height=" + nY + " channels=" + nC + " slices=" + nZ + " frames=" + nT);
	while (!isOpen(imageTitle)) {
	}
	wait(1);
	return imageTitle;
}

function iteratePoint(rr, theta, phi, n) {
	c = newArray(- 0.1, 0.5, 0.2);
	Threshold = 1e5;
	for (cntr = 0; cntr < n; cntr++) {
		x = pow(rr, n) * sin(n * theta) * cos(n * phi) + c[0];
		y = pow(rr, n) * sin(n * theta) * sin(n * phi) + c[1];
		z = pow(rr, n) * cos(n * theta) + c[2];

		rr = sqrt(pow(x,2) + pow(y,2) + pow(z,2));
		phi = atan2(y, x);
		theta = acos(z / rr);
		if (isNaN(theta)) {
			theta = 0;
		}
		
		if (rr < Threshold) {
			XYZ = newArray(x, y, z);
		} else {
			cntr = n;
			XYZ = newArray(NaN, NaN, NaN);
		}
	}
	return XYZ;
}

function generatePhoto51(imageTitle) {
	selectWindow(imageTitle);
	wait(1);
	imWidth = getWidth;
	imHeight = getHeight;
	imWidth_ = 2 * imWidth;
	imHeight_ = 2 * imHeight;
	
	run("32-bit");
	nImages_ = nImages;
	run("Z Project...", "projection=[Sum Slices]");
	while(nImages_ == nImages) {
	}
	nImages_ = nImages;
	projectionTitle = "Double-helix projection";
	rename(projectionTitle);
	//run("Macro...", "code=[v = v * (0.54 - 0.46 * cos(2 * PI * (1 / (w - 1)) * x)) * (0.54 - 0.46 * cos(2 * PI * (1 / (h - 1)) * y))]");
	run("Canvas Size...", "width=" + imWidth_ + " height=" + imHeight_ + " position=Center zero");
	while(imWidth_ != getWidth) {
	}
	run("FFT Options...", "raw do");
	while(nImages_ == nImages) {
	}
	nImages_ = nImages;
	run("8-bit");
	ftTitle = "\"Photo 51\"";
	rename(ftTitle);
	run("Canvas Size...", "width=" + imWidth + " height=" + imHeight + " position=Center zero");
	ftWidth = getWidth;
	ftHeight = getHeight;
	ftAll = ftWidth * ftHeight;
	ftData = newArray(ftAll);
	for (y = 0; y < ftHeight; y++) {
		for (x = 0; x < ftWidth; x++) {
			ftData[x + y * ftWidth] = getPixel(x, y);
		}
	}
	close(ftTitle);
	while(isOpen(ftTitle)) {
	}
	wait(1);
	newImage(ftTitle, "8-bit black", ftWidth, ftHeight, 1);
	while(!isOpen(ftTitle)) {
	}
	for (y = 0; y < ftHeight; y++) {
		for (x = 0; x < ftWidth; x++) {
			setPixel(x, y, ftData[x + y * ftWidth]);
		}
	}
	run("Invert LUT");		
	run("Enhance Contrast", "saturated=0.35");
	photo51Text = "Photo 51";
	fontSize = 18;
	setFont("SansSerif" , fontSize, "antialiased");
	run("RGB Color");
	setColor(255, 0, 0);
	drawString(photo51Text, floor((getWidth - getStringWidth(photo51Text)) / 2), fontSize * 2);

	selectWindow(projectionTitle);
	run("Canvas Size...", "width=" + imWidth + " height=" + imHeight + " position=Center zero");
	while(imWidth != getWidth) {
	}
	run("Enhance Contrast", "saturated=0.35");
	run("RGB Color");
	run("Combine...", "stack1=[" + projectionTitle + "] stack2=[" + ftTitle + "]");
}

