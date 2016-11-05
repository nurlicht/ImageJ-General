// Program: isoSurface.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Keeps only pixels with intensities around a given isosurface value. This isosurface has the same meaning as the mathematical definition and the implementations used in numerical software such as Matlab, Mathematica, and some Python distributions. It is different from an "isosurface" generated in UCSF Chimera, ImageJ 3D Viewer (and possibly other hardware-accelerated programs using default settings of OpenGL).

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	selectActiveImage();
	normalStackFlag = checkStackDimensions();
	if (normalStackFlag) {
		isoSurfaceValue = getIsoSurfaceValue();
		isoSurfaceStackTitle = generateIsoSurfaceStack(isoSurfaceValue);
	}
}

function Initialize() {
  	showStatus("Basic initialization ...");
	print("\\Clear");
  	setBatchMode("exit and display");
  	setBatchMode(false);
}

function checkStackDimensions() {
	normalStackFlag = true;
	Stack.getDimensions(width, height, channels, slices, frames);
	if (slices == 1) {
		if (frames > 1) {
			tempData = slices;
			slices = frames;
			frames = tempData;
			Stack.setDimensions(width, height, channels, slices, frames);
			waitForUser("Frames and Slices were swapped.");
			wait(1);
		} else {
			waitForUser("A Z-stack is required.");
			wait(1);
			normalStackFlag = false;
		}
	} else if (frames > 1) {
		waitForUser("A hyperstack is not allowed.");
		wait(1);
		normalStackFlag = false;
	}
	if (channels > 1) {
		waitForUser("Multi-channel images are not allowed.");
		wait(1);
		normalStackFlag = false;
	}
	return normalStackFlag;
}

function selectActiveImage() {
	Delay = 100;
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
  	//return !is("composite");
}

function getIsoSurfaceValue() {
	getMinAndMax(min, max);
	isoSurfaceValue = (min + max) / 2;
	neighborhoodFlag = true;
	neighborhoodText = "Neighborhood of ";
	Dialog.create("IsoSurface Value");
	Dialog.addNumber("IsoSurface Value", isoSurfaceValue);
	Dialog.addCheckbox("Use a small neighborhood in the histogram", neighborhoodFlag);
	Dialog.show();
	isoSurfaceValue = parseFloat(Dialog.getNumber());
	neighborhoodFlag = Dialog.getCheckbox();
	if (neighborhoodFlag) {
		isoSurfaceValue = neighborhoodText + isoSurfaceValue;
	}
	return isoSurfaceValue;
}

function generateIsoSurfaceStack(isoSurfaceValue) {
	neighborhoodText = "Neighborhood of ";
	if (startsWith(isoSurfaceValue, neighborhoodText)) {
		isoSurfaceValue = substring(isoSurfaceValue, lengthOf(neighborhoodText));
		isoSurfaceValue = parseFloat(isoSurfaceValue);

		getMinAndMax(min, max);
		nBins = 40;	//Size of the neighborhood in the histogram
		binSize = (max - min) / nBins;
		
		v1 = isoSurfaceValue - binSize / 2;
		v2 = isoSurfaceValue + binSize / 2;
		if (v1 < min) {
			v1 = min;
			v2 = v1 + binSize;
		}
		if (v2 > max) {
			v2 = max;
			v1 = v2 - binSize;
		}
	} else {
		v1 = parseFloat(isoSurfaceValue);
		v2 = v1;
	}
	nImages_ = nImages;
	run("Duplicate...", "duplicate");
	while (nImages_ == nImages) {
	}
	wait(1);
	isoSurfaceStackTitle = getTitle();
	run("Macro...", "code=[v = 255 * (v >= " + v1 + ") * (v <= " + v2 + ")] stack");
	run("Enhance Contrast", "saturated=0");
	wait(100);
	return isoSurfaceStackTitle;
}
