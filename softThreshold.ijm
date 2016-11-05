// Program: softThreshold.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Offers a solution to the trade-off between allowing some background ("small" threshold level) and sacrificing weak real features ("large" threshold level). It also eliminates the clipping caused by single-level thresholding. Soft thresholding can be specifically helpful for pre-processing prior to 3D visualization. Depending on dataset (especially for segmentation purposes), it is advisable that hysteresis thresholding be also checked out.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	grayScaleFlag = selectActiveImage();
	Stack.getDimensions(width, height, channels, slices, frames);
	if (channels == 1) {
		twoThresholds = getTwoThresholds();
		applySoftThreshold(twoThresholds);
	} else {
		waitForUser("Multi-channel images are not allowed.");
		wait(10);
	}
}

function Initialize() {
  	showStatus("Basic initialization ...");
	print("\\Clear");
  	setBatchMode("exit and display");
  	setBatchMode(false);
  	waitForUser("A single-channel gray-scale (non-RGB) image is required.");
  	wait(10);
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
  	return is("grayscale");
}

function getTwoThresholds() {
	Delay = 10;
	run("Threshold...");
	setAutoThreshold("Default dark stack");	
	wait(Delay);
	waitForUser("Please scan the threshold level and write down the Lower and Upper bounds. Press OK when ready.");
	wait(Delay);

	getStatistics(area, mean, min, max, std, histogram);
	twoThresholds = newArray(min, max);
	
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
  	resetThreshold();
	wait(Delay);
	return twoThresholds;
}

function applySoftThreshold(twoThresholds) {
	min = twoThresholds[0];
	max = twoThresholds[1];
	resetThreshold();
	wait(1);
	run("Macro...", "code=[v = v * ((v>" + max + ") * 1 + ((v <=" + max + ") & (v >=" + min + 
		")) * pow(sin((PI / 2) * (v - " + min + ") / (" + max + " - " + min + ") ), 2) )] stack");
	wait(10);
	return true;
}
