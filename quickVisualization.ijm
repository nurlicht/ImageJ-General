macro "Main" {
	imageTitle = getSingleStack();
	subtractBackground(imageTitle);
	filterImage();

	selectWindow_(imageTitle);
	nImages_ = nImages;
	run("Z Project...", "projection=[Standard Deviation]");	
	while (nImages_ == nImages) {
	}

	selectWindow_(imageTitle);
	nImages_ = nImages;
	run("Temporal-Color Code", "lut=phase start=1 end=1800 create");
	while (nImages_ == nImages) {
	}
}

function subtractBackground(imageTitle) {
	selectWindow_(imageTitle);
	nImages_ = nImages;
	run("Z Project...", "projection=[Average Intensity]");
	while (nImages_ == nImages) {
	}
	avgTitle = getTitle();
	nImages_ = nImages;
	imageCalculator("Subtract create 32-bit stack", imageTitle, avgTitle);
	while (nImages_ == nImages) {
	}
	backgroundRemovedTitle = getTitle();
	run("8-bit");
	run("Macro...", "code=[v = 255 - v] stack");
	close_(avgTitle);
	close_(imageTitle);
	selectWindow_(backgroundRemovedTitle);
	rename_(imageTitle);
}

function getSingleStack() {
	continueFlag = true;
	while (continueFlag) {
		nImages_ = nImages;
		if (nImages_ > 1) {
			waitForUser("" + nImages_ + " images are open. Please close unwanted images; then press OK");
			wait(1);
		} else if (nImages_ < 1) {
			waitForUser("Please open the image series; then press OK");
			wait(1);
		} else {
			if (nSlices > 1) {
				continueFlag = false;
			} else {
				waitForUser("The imge is not a series. Please open the image series; then press OK");
				wait(1);
			}
		}
	}
	return getTitle;
}

function filterImage() {
	run("Bandpass Filter...", "filter_large=40 filter_small=4 suppress=None tolerance=5 autoscale process");	
}

function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while (getTitle != imageTitle) {
	}
}

function rename_(imageTitle) {
	rename(imageTitle);
	while (!isOpen(imageTitle)) {
	}
}

function close_(imageTitle) {
	close(imageTitle);
	while (isOpen(imageTitle)) {
	}
}
